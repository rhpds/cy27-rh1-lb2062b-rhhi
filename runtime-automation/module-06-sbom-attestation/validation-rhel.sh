#!/bin/sh
echo "Validating module-06" >> /tmp/progress.log

. /home/rhel/.bashrc 2>/dev/null || true

IMAGE_DIGEST=$(cat /home/rhel/image.digest 2>/dev/null)
if [ -z "$IMAGE_DIGEST" ]; then
    fail_validation - <<'EOF'
**Validation incomplete:** `~/image.digest` is missing or empty.

Review **“Push Your Application Image”** in Module 4, then validate again.
EOF
fi

ATTEST_OUTPUT=$(runuser -l rhel -c "COSIGN_PASSWORD='' /usr/local/bin/cosign verify-attestation --insecure-ignore-tlog=true --key /home/rhel/cosign.pub --type spdxjson ${REGISTRY}/rhhi-demo@${IMAGE_DIGEST}" 2>>/tmp/progress.log)

if [ $? -ne 0 ]; then
    fail_validation - <<'EOF'
**Validation incomplete:** The SBOM attestation could not be verified.

Review **“Attach the SBOM as a Signed Attestation”** and **“Verify the SBOM Attestation”** in Module 6, then validate again.
EOF
fi

PKG_COUNT=$(echo "$ATTEST_OUTPUT" | head -1 | jq -r '.payload' | base64 -d | jq '.predicate.packages | length')
if [ -z "$PKG_COUNT" ] || [ "$PKG_COUNT" -lt 20 ]; then
    fail_validation "**Validation incomplete:** The attested SBOM package count (${PKG_COUNT:-unavailable}) is below 20." \
      "" "Review **“Verify the SBOM Attestation”** in Module 6, then validate again."
fi

echo "PASS: SBOM attestation verified with ${PKG_COUNT} packages" >> /tmp/progress.log
exit 0
