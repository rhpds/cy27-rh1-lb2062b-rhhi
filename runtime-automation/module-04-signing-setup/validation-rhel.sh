#!/bin/sh
echo "Validating module-04" >> /tmp/progress.log

. /home/rhel/.bashrc 2>/dev/null || true

# --authfile keeps skopeo off its unreadable default path under runuser -l (no
# XDG_RUNTIME_DIR); the registry is anonymous so a missing file is harmless.
AUTHFILE=/home/rhel/.config/containers/auth.json

# Module 5 signs with these keys.
if [ ! -f /home/rhel/cosign.key ] || [ ! -f /home/rhel/cosign.pub ]; then
    echo "FAIL: cosign key pair not found" >> /tmp/progress.log
    echo "HINT: Generate the cosign key pair as shown in this module" >> /tmp/progress.log
    exit 1
fi

# Module 5 signs rhhi-demo@<image.digest> and verifies rhhi-demo:hardened by tag, so the
# registry tag must resolve to the digest recorded in ~/image.digest.
if [ ! -f /home/rhel/image.digest ]; then
    echo "FAIL: image.digest not found" >> /tmp/progress.log
    echo "HINT: Push the image and capture its digest as shown in this module" >> /tmp/progress.log
    exit 1
fi
IMAGE_DIGEST=$(cat /home/rhel/image.digest)
REG_IMAGE_DIGEST=$(runuser -l rhel -c "skopeo inspect --authfile ${AUTHFILE} docker://${REGISTRY}/rhhi-demo:hardened | jq -r .Digest" 2>/dev/null)
if [ "$REG_IMAGE_DIGEST" != "$IMAGE_DIGEST" ]; then
    echo "FAIL: rhhi-demo:hardened in the registry does not match ~/image.digest" >> /tmp/progress.log
    echo "HINT: Push the image and capture its digest as shown in this module" >> /tmp/progress.log
    exit 1
fi

# Module 5 signs python@<python.digest> and verifies python:3.12 by tag, so the registry
# tag must resolve to the digest recorded in ~/python.digest.
if [ ! -f /home/rhel/python.digest ]; then
    echo "FAIL: python.digest not found (mirrored vendor image digest)" >> /tmp/progress.log
    echo "HINT: Mirror the vendor image and capture its digest as shown in this module" >> /tmp/progress.log
    exit 1
fi
PYTHON_DIGEST=$(cat /home/rhel/python.digest)
REG_PYTHON_DIGEST=$(runuser -l rhel -c "skopeo inspect --authfile ${AUTHFILE} docker://${REGISTRY}/python:3.12 | jq -r .Digest" 2>/dev/null)
if [ "$REG_PYTHON_DIGEST" != "$PYTHON_DIGEST" ]; then
    echo "FAIL: python:3.12 in the registry does not match ~/python.digest" >> /tmp/progress.log
    echo "HINT: Mirror the vendor image and capture its digest as shown in this module" >> /tmp/progress.log
    exit 1
fi

echo "PASS: cosign keys present; rhhi-demo and python mirror digests match what Module 5 will sign" >> /tmp/progress.log
exit 0
