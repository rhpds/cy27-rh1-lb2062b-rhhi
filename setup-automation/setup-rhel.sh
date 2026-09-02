#!/bin/bash
USER=rhel

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

# Install certbot
dnf install -y certbot
echo "Certbot installed" >> /tmp/progress.log

# Get ZeroSSL certificate for the registry hostname
set +x
certbot certonly \
  --eab-kid "${ZEROSSL_EAB_KEY_ID}" \
  --eab-hmac-key "${ZEROSSL_HMAC_KEY}" \
  --server "https://acme.zerossl.com/v2/DV90" \
  --standalone --preferred-challenges http \
  -d registry-"${GUID}"."${DOMAIN}" \
  --non-interactive --agree-tos -m trackbot@instruqt.com -v
rm -f /var/log/letsencrypt/letsencrypt.log
set -x
echo "SSL cert obtained" >> /tmp/progress.log

# Start unauthenticated SSL registry
REGISTRY_HOST="registry-${GUID}.${DOMAIN}"
podman run -d \
  --name registry \
  -p 443:5000 \
  -v /etc/letsencrypt/live/${REGISTRY_HOST}/fullchain.pem:/certs/fullchain.pem:ro \
  -v /etc/letsencrypt/live/${REGISTRY_HOST}/privkey.pem:/certs/privkey.pem:ro \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/fullchain.pem \
  -e REGISTRY_HTTP_TLS_KEY=/certs/privkey.pem \
  quay.io/mmicene/registry:2
echo "Registry started at ${REGISTRY_HOST}" >> /tmp/progress.log

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
