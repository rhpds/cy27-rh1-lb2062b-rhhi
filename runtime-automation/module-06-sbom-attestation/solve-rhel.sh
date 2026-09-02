#!/bin/sh
echo "Solving module-06: SBOM Attestation" >> /tmp/progress.log

# Load REGISTRY from bashrc
. /home/rhel/.bashrc 2>/dev/null || true

IMAGE_DIGEST=$(cat /home/rhel/image.digest 2>/dev/null)

if [ ! -f /home/rhel/rhhi-demo.spdx ]; then
    echo "FAIL: SBOM not found at /home/rhel/rhhi-demo.spdx" >> /tmp/progress.log
    echo "HINT: Did you complete module 2 to generate the SBOM with syft?" >> /tmp/progress.log
    exit 1
fi

runuser -l rhel -c "COSIGN_PASSWORD='' /usr/local/bin/cosign attest --tlog-upload=false --yes --key /home/rhel/cosign.key --predicate /home/rhel/rhhi-demo.spdx --type spdxjson ${REGISTRY}/rhhi-demo@${IMAGE_DIGEST}" >> /tmp/progress.log 2>&1

echo "module-06 solve complete" >> /tmp/progress.log
