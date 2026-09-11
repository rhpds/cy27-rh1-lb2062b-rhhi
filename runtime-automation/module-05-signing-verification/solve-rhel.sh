#!/bin/sh
echo "Solving module-05: Image Signing and Verification" >> /tmp/progress.log

# Load REGISTRY from bashrc
. /home/rhel/.bashrc 2>/dev/null || true

# Generate the key pair that module-05 introduces
runuser -l rhel -c "cd ~ && COSIGN_PASSWORD='' /usr/local/bin/cosign generate-key-pair" >> /tmp/progress.log 2>&1

IMAGE_DIGEST=$(cat /home/rhel/image.digest 2>/dev/null)
runuser -l rhel -c "COSIGN_PASSWORD='' /usr/local/bin/cosign sign --tlog-upload=false --yes --key /home/rhel/cosign.key ${REGISTRY}/rhhi-demo@${IMAGE_DIGEST}" >> /tmp/progress.log 2>&1

# Re-sign the mirrored vendor image from module-04 with the internal key
PYTHON_DIGEST=$(cat /home/rhel/python.digest 2>/dev/null)
if [ -n "$PYTHON_DIGEST" ]; then
    runuser -l rhel -c "COSIGN_PASSWORD='' /usr/local/bin/cosign sign --tlog-upload=false --yes --key /home/rhel/cosign.key ${REGISTRY}/python@${PYTHON_DIGEST}" >> /tmp/progress.log 2>&1
fi

echo "module-05 solve complete" >> /tmp/progress.log
