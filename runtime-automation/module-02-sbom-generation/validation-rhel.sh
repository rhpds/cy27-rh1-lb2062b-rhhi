#!/bin/sh
echo "Validating module-02" >> /tmp/progress.log

SBOM_FILE="/home/rhel/rhhi-demo.spdx"

if [ ! -f "$SBOM_FILE" ]; then
    echo "FAIL: SBOM file not found at ~/rhhi-demo.spdx" >> /tmp/progress.log
    echo "HINT: Did you complete Step 2 to generate the SBOM with syft?" >> /tmp/progress.log
    exit 1
fi

if ! jq empty "$SBOM_FILE" > /dev/null 2>&1; then
    echo "FAIL: ~/rhhi-demo.spdx exists but is not valid JSON" >> /tmp/progress.log
    echo "HINT: The SBOM file exists but isn't valid JSON - try regenerating it with syft" >> /tmp/progress.log
    exit 1
fi

PKG_COUNT=$(jq '.packages | length' "$SBOM_FILE" 2>/dev/null)
if [ -z "$PKG_COUNT" ]; then
    echo "FAIL: Could not read package count from SBOM" >> /tmp/progress.log
    echo "HINT: The SBOM file seems malformed - try regenerating it with syft" >> /tmp/progress.log
    exit 1
fi

if [ "$PKG_COUNT" -le 20 ]; then
    echo "FAIL: SBOM contains only $PKG_COUNT packages (expected > 20)" >> /tmp/progress.log
    echo "HINT: The SBOM has only $PKG_COUNT packages - did you run syft against rhhi-demo:hardened?" >> /tmp/progress.log
    exit 1
fi

echo "PASS: SBOM found at ~/rhhi-demo.spdx with $PKG_COUNT packages" >> /tmp/progress.log
exit 0
