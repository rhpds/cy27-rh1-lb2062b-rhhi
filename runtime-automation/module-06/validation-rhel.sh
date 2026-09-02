#!/bin/sh
echo "Validating module-06" >> /tmp/progress.log

. /home/rhel/.bashrc 2>/dev/null || true

IMAGE_DIGEST=$(cat /home/rhel/image.digest 2>/dev/null)
if [ -z "$IMAGE_DIGEST" ]; then
    echo "FAIL: image.digest not found" >> /tmp/progress.log
    echo "HINT: Did you complete module 4 to push the image with --digestfile?" >> /tmp/progress.log
    exit 1
fi

ATTEST_OUTPUT=$(runuser -l rhel -c "COSIGN_PASSWORD='' /usr/local/bin/cosign verify-attestation --insecure-ignore-tlog=true --key /home/rhel/cosign.pub --type spdxjson ${REGISTRY}/rhhi-demo@${IMAGE_DIGEST}" 2>>/tmp/progress.log)

if [ $? -ne 0 ]; then
    echo "FAIL: SBOM attestation not found or invalid" >> /tmp/progress.log
    echo "HINT: Did you complete the cosign attest step with the SBOM file as the predicate?" >> /tmp/progress.log
    exit 1
fi

PKG_COUNT=$(echo "$ATTEST_OUTPUT" | head -1 | jq -r '.payload' | base64 -d | jq '.predicate.packages | length')
if [ -z "$PKG_COUNT" ] || [ "$PKG_COUNT" -lt 20 ]; then
    echo "FAIL: SBOM package count ($PKG_COUNT) is unexpectedly low" >> /tmp/progress.log
    echo "HINT: Attestation found but package count is low - was the correct SBOM attached?" >> /tmp/progress.log
    exit 1
fi

echo "PASS: SBOM attestation verified with ${PKG_COUNT} packages" >> /tmp/progress.log
exit 0
