#!/bin/sh
echo "Validating module-05" >> /tmp/progress.log

. /home/rhel/.bashrc 2>/dev/null || true

AUTHFILE=/home/rhel/.config/containers/auth.json

# Key pair must exist before any signing could have happened
if [ ! -f /home/rhel/cosign.key ] || [ ! -f /home/rhel/cosign.pub ]; then
    fail_validation - <<'EOF'
The Cosign key pair (`~/cosign.key` and `~/cosign.pub`) was not found.

Review **“Generate a Cosign Key Pair”**, then validate again.
EOF
fi

# Verify rhhi-demo:hardened is signed with the local key pair
IMAGE_DIGEST=$(cat /home/rhel/image.digest 2>/dev/null)
if [ -z "$IMAGE_DIGEST" ]; then
    fail_validation - <<'EOF'
`~/image.digest` is missing or empty.

Review **“Push Your Application Image”** in Module 4, then validate again.
EOF
fi

if ! runuser -l rhel -c "COSIGN_PASSWORD='' /usr/local/bin/cosign verify --insecure-ignore-tlog=true --key /home/rhel/cosign.pub ${REGISTRY}/rhhi-demo:hardened" >> /tmp/progress.log 2>&1; then
    fail_validation - <<'EOF'
The signature for `rhhi-demo:hardened` could not be verified.

Review **“Sign the Image”** and **“Verify the Signature”**, then validate again.
EOF
fi

# Verify python:3.12 mirror is signed with the local key pair
PYTHON_DIGEST=$(cat /home/rhel/python.digest 2>/dev/null)
if [ -z "$PYTHON_DIGEST" ]; then
    fail_validation - <<'EOF'
`~/python.digest` is missing or empty.

Review **“Copy With a Preserved Digest”** in Module 4, then validate again.
EOF
fi

if ! runuser -l rhel -c "COSIGN_PASSWORD='' /usr/local/bin/cosign verify --insecure-ignore-tlog=true --key /home/rhel/cosign.pub ${REGISTRY}/python:3.12" >> /tmp/progress.log 2>&1; then
    fail_validation - <<'EOF'
The signature for the mirrored `python:3.12` image could not be verified.

Review **“Re-sign the Mirrored Image”**, then validate again.
EOF
fi

echo "PASS: cosign key pair present; rhhi-demo and python signatures verified" >> /tmp/progress.log
exit 0
