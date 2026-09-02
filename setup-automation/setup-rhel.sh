#!/bin/bash
USER=rhel

# Installs certbot, requests a ZeroSSL cert (retried against transient ACME failures),
# starts a TLS registry, and validates it responds. Pulled raw from lab-setup/common.sh
# so this lab does not depend on the library. Requires ZEROSSL_EAB_KEY_ID and
# ZEROSSL_HMAC_KEY. Usage: setup_ssl_registry <hostname> [htpasswd_file]
setup_ssl_registry() {
  local HOST="$1"
  local HTPASSWD="$2"
  local CERT_DIR="/etc/letsencrypt/live/${HOST}"
  local MAX_CERT_RETRIES=3
  local RETRY=0

  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
  dnf install -y certbot

  while [ $RETRY -lt $MAX_CERT_RETRIES ]; do
    set +x
    certbot certonly \
      --eab-kid "${ZEROSSL_EAB_KEY_ID}" \
      --eab-hmac-key "${ZEROSSL_HMAC_KEY}" \
      --server "https://acme.zerossl.com/v2/DV90" \
      --standalone --preferred-challenges http \
      -d "${HOST}" \
      --non-interactive --agree-tos -m trackbot@instruqt.com || true
    set -x

    if [ -f "${CERT_DIR}/fullchain.pem" ] && [ -f "${CERT_DIR}/privkey.pem" ]; then
      echo "SSL certificate obtained for ${HOST}" >> /tmp/progress.log
      break
    fi

    RETRY=$((RETRY + 1))
    echo "Certificate attempt ${RETRY} of ${MAX_CERT_RETRIES} failed, retrying in 15 seconds..." >> /tmp/progress.log
    sleep 15
  done

  if [ ! -f "${CERT_DIR}/fullchain.pem" ] || [ ! -f "${CERT_DIR}/privkey.pem" ]; then
    echo "FATAL: Failed to obtain SSL certificate for ${HOST} after ${MAX_CERT_RETRIES} attempts" >> /tmp/progress.log
    exit 1
  fi

  [ -f /var/log/letsencrypt/letsencrypt.log ] && rm /var/log/letsencrypt/letsencrypt.log || true

  if [ -n "${HTPASSWD}" ]; then
    podman run -d \
      --name registry \
      -p 443:5000 \
      -v "${HTPASSWD}":/auth/htpasswd:ro \
      -e REGISTRY_AUTH=htpasswd \
      -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
      -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
      -v "${CERT_DIR}/fullchain.pem":/certs/fullchain.pem:ro \
      -v "${CERT_DIR}/privkey.pem":/certs/privkey.pem:ro \
      -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/fullchain.pem \
      -e REGISTRY_HTTP_TLS_KEY=/certs/privkey.pem \
      quay.io/mmicene/registry:2
  else
    podman run -d \
      --name registry \
      -p 443:5000 \
      -v "${CERT_DIR}/fullchain.pem":/certs/fullchain.pem:ro \
      -v "${CERT_DIR}/privkey.pem":/certs/privkey.pem:ro \
      -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/fullchain.pem \
      -e REGISTRY_HTTP_TLS_KEY=/certs/privkey.pem \
      quay.io/mmicene/registry:2
  fi

  local MAX_REG_RETRIES=5
  local HTTP_CODE
  RETRY=0
  while [ $RETRY -lt $MAX_REG_RETRIES ]; do
    HTTP_CODE=$(curl -sk -o /dev/null -w '%{http_code}' "https://${HOST}/v2/" 2>/dev/null) || true
    if [ "${HTTP_CODE}" = "401" ] || [ "${HTTP_CODE}" = "200" ]; then
      echo "Registry responding at ${HOST} (HTTP ${HTTP_CODE})" >> /tmp/progress.log
      return 0
    fi
    RETRY=$((RETRY + 1))
    echo "Registry not responding yet (HTTP ${HTTP_CODE}), retry ${RETRY} of ${MAX_REG_RETRIES}..." >> /tmp/progress.log
    sleep 5
  done

  echo "FATAL: Registry not responding after ${MAX_REG_RETRIES} attempts" >> /tmp/progress.log
  podman logs registry >> /tmp/progress.log 2>&1
  exit 1
}

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "Starting setup for zt-scan-sign" > /tmp/progress.log

chmod 666 /tmp/progress.log

# Fetch setup files from the lab git repository
TMPDIR=/tmp/lab-setup-$$
git clone --single-branch --branch ${GIT_BRANCH:-main} --no-checkout \
  --depth=1 --filter=tree:0 ${GIT_REPO} $TMPDIR
git -C $TMPDIR sparse-checkout set --no-cone /content/modules/ROOT/examples/flask
git -C $TMPDIR checkout
SETUP_FILES=$TMPDIR/content/modules/ROOT/examples/flask

# Install grype
GRYPE_VERSION=v0.111.0
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | \
  sh -s -- -b /usr/local/bin ${GRYPE_VERSION}
runuser -l rhel -c "grype db update"
echo "Grype installed" >> /tmp/progress.log

# Install cosign
COSIGN_VERSION=v2.6.3
curl -LO https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64
install -m 755 cosign-linux-amd64 /usr/local/bin/cosign
rm cosign-linux-amd64
echo "Cosign installed" >> /tmp/progress.log

# Install syft
SYFT_VERSION=v1.42.4
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | \
  sh -s -- -b /usr/local/bin ${SYFT_VERSION}
echo "Syft installed" >> /tmp/progress.log

# Get a ZeroSSL cert and start the unauthenticated TLS registry, retrying the cert
# against transient ACME failures and confirming the registry responds before continuing.
REGISTRY_HOST="registry-${GUID}.${DOMAIN}"
setup_ssl_registry "${REGISTRY_HOST}"

# Write REGISTRY to rhel user's bashrc for persistence across terminal sessions
touch /home/rhel/.bashrc
chown rhel:rhel /home/rhel/.bashrc
echo "export REGISTRY=${REGISTRY_HOST}" >> /home/rhel/.bashrc

# Pull base images for the Flask demo app
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/python:3.12-builder"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/python:3.12"
runuser -l rhel -c "podman pull registry.access.redhat.com/ubi10/ubi"
echo "Base images pulled" >> /tmp/progress.log

# Copy Flask app files from the lab repo
mkdir -p /home/rhel/flask
cp $SETUP_FILES/app.py /home/rhel/flask/app.py
cp $SETUP_FILES/Containerfile /home/rhel/flask/Containerfile
cp $SETUP_FILES/Containerfile.ubi /home/rhel/flask/Containerfile.ubi
chown -R rhel:rhel /home/rhel/flask
echo "Flask app files copied" >> /tmp/progress.log

# Build rhhi-demo:hardened (hardened multi-stage Python 3.12)
runuser -l rhel -c "podman build --net=host -t rhhi-demo:hardened -f /home/rhel/flask/Containerfile /home/rhel/flask"
echo "rhhi-demo:hardened built" >> /tmp/progress.log

# Build rhhi-demo:ubi (single-stage UBI Python 3.12 for CVE comparison)
runuser -l rhel -c "podman build --net=host -t rhhi-demo:ubi -f /home/rhel/flask/Containerfile.ubi /home/rhel/flask"
echo "rhhi-demo:ubi built" >> /tmp/progress.log

# Cleanup
rm -rf $TMPDIR

echo "Setup complete" >> /tmp/progress.log
