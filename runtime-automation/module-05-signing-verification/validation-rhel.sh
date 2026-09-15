#!/bin/sh
echo "Validating module-05" >> /tmp/progress.log

. /home/rhel/.bashrc 2>/dev/null || true

AUTHFILE=/home/rhel/.config/containers/auth.json

# Key pair must exist before any signing could have happened
if [ ! -f /home/rhel/cosign.key ] || [ ! -f /home/rhel/cosign.pub ]; then
    echo "FAIL: cosign key pair not found (expected ~/cosign.key and ~/cosign.pub)" >> /tmp/progress.log
    echo "HINT: Generate the key pair as shown in this module: COSIGN_PASSWORD='' cosign generate-key-pair" >> /tmp/progress.log
    exit 1
fi

# Verify rhhi-demo:hardened is signed with the local key pair
IMAGE_DIGEST=$(cat /home/rhel/image.digest 2>/dev/null)
if [ -z "$IMAGE_DIGEST" ]; then
    echo "FAIL: image.digest not found" >> /tmp/progress.log
    echo "HINT: Did you complete module 4 to push the image with --digestfile?" >> /tmp/progress.log
    exit 1
fi

if ! runuser -l rhel -c "COSIGN_PASSWORD='' /usr/local/bin/cosign verify --insecure-ignore-tlog=true --key /home/rhel/cosign.pub ${REGISTRY}/rhhi-demo:hardened" >> /tmp/progress.log 2>&1; then
    echo "FAIL: rhhi-demo:hardened signature could not be verified" >> /tmp/progress.log
    echo "HINT: Sign the image as shown in this module: cosign sign --key cosign.key registry-.../rhhi-demo@\${IMAGE_DIGEST}" >> /tmp/progress.log
    exit 1
fi

# Verify python:3.12 mirror is signed with the local key pair
PYTHON_DIGEST=$(cat /home/rhel/python.digest 2>/dev/null)
if [ -z "$PYTHON_DIGEST" ]; then
    echo "FAIL: python.digest not found" >> /tmp/progress.log
    echo "HINT: Did you complete module 4 to mirror the vendor image with --digestfile?" >> /tmp/progress.log
    exit 1
fi

if ! runuser -l rhel -c "COSIGN_PASSWORD='' /usr/local/bin/cosign verify --insecure-ignore-tlog=true --key /home/rhel/cosign.pub ${REGISTRY}/python:3.12" >> /tmp/progress.log 2>&1; then
    echo "FAIL: python:3.12 mirror signature could not be verified" >> /tmp/progress.log
    echo "HINT: Re-sign the mirrored vendor image as shown in this module" >> /tmp/progress.log
    exit 1
fi

echo "PASS: cosign key pair present; rhhi-demo and python signatures verified" >> /tmp/progress.log
exit 0
