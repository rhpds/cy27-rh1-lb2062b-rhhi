#!/bin/sh
echo "Validating module-05" >> /tmp/progress.log

. /home/rhel/.bashrc 2>/dev/null || true

IMAGE_DIGEST=$(cat /home/rhel/image.digest 2>/dev/null)
if [ -z "$IMAGE_DIGEST" ]; then
    echo "FAIL: image.digest not found" >> /tmp/progress.log
    echo "HINT: Did you complete module 4 to push the image with --digestfile?" >> /tmp/progress.log
    exit 1
fi

if ! runuser -l rhel -c "/usr/local/bin/cosign verify --insecure-ignore-tlog=true --key /home/rhel/cosign.pub ${REGISTRY}/rhhi-demo@${IMAGE_DIGEST}" >> /tmp/progress.log 2>&1; then
    echo "FAIL: Image signature verification failed" >> /tmp/progress.log
    echo "HINT: Did you complete the cosign sign step? Verify your key and image digest are correct" >> /tmp/progress.log
    exit 1
fi

# Verify the re-signed mirrored vendor image from module-04
PYTHON_DIGEST=$(cat /home/rhel/python.digest 2>/dev/null)
if [ -z "$PYTHON_DIGEST" ]; then
    echo "FAIL: python.digest not found" >> /tmp/progress.log
    echo "HINT: Did you complete module 4 to mirror the vendor image with --digestfile?" >> /tmp/progress.log
    exit 1
fi

if ! runuser -l rhel -c "/usr/local/bin/cosign verify --insecure-ignore-tlog=true --key /home/rhel/cosign.pub ${REGISTRY}/python@${PYTHON_DIGEST}" >> /tmp/progress.log 2>&1; then
    echo "FAIL: mirrored vendor image signature verification failed" >> /tmp/progress.log
    echo "HINT: Did you re-sign the mirrored python image with your cosign.key?" >> /tmp/progress.log
    exit 1
fi

echo "PASS: application image and re-signed mirrored image both verified" >> /tmp/progress.log
exit 0
