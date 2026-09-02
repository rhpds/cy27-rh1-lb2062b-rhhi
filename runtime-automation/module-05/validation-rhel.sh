#!/bin/sh
echo "Validating module-05" >> /tmp/progress.log

. /home/rhel/.bashrc 2>/dev/null || true

IMAGE_DIGEST=$(cat /home/rhel/image.digest 2>/dev/null)
if [ -z "$IMAGE_DIGEST" ]; then
    echo "FAIL: image.digest not found" >> /tmp/progress.log
    echo "HINT: Did you complete module 4 to push the image with --digestfile?" >> /tmp/progress.log
    exit 1
fi

if runuser -l rhel -c "/usr/local/bin/cosign verify --insecure-ignore-tlog=true --key /home/rhel/cosign.pub ${REGISTRY}/rhhi-demo@${IMAGE_DIGEST}" >> /tmp/progress.log 2>&1; then
    echo "PASS: Image signature verified" >> /tmp/progress.log
    exit 0
else
    echo "FAIL: Image signature verification failed" >> /tmp/progress.log
    echo "HINT: Did you complete the cosign sign step? Verify your key and image digest are correct" >> /tmp/progress.log
    exit 1
fi
