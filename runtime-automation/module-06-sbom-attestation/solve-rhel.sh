#!/bin/sh
echo "Solving module-06: SBOM Attestation" >> /tmp/progress.log

# Load REGISTRY from bashrc
. /home/rhel/.bashrc 2>/dev/null || true

IMAGE_DIGEST=$(cat /home/rhel/image.digest 2>/dev/null)

if [ ! -f /home/rhel/rhhi-demo.spdx ]; then
    fail_validation - <<'EOF'
**Unable to complete this stage:** SBOM file `~/rhhi-demo.spdx` was not found.

Review **“Step 2: Generate a Machine-Readable SPDX SBOM”** in Module 2, then try again.
EOF
fi

runuser -l rhel -c "COSIGN_PASSWORD='' /usr/local/bin/cosign attest --tlog-upload=false --yes --key /home/rhel/cosign.key --predicate /home/rhel/rhhi-demo.spdx --type spdxjson ${REGISTRY}/rhhi-demo@${IMAGE_DIGEST}" >> /tmp/progress.log 2>&1

echo "module-06 solve complete" >> /tmp/progress.log
