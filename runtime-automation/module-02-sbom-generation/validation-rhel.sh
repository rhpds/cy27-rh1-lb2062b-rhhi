#!/bin/sh
echo "Validating module-02" >> /tmp/progress.log

SBOM_FILE="/home/rhel/rhhi-demo.spdx"

if [ ! -f "$SBOM_FILE" ]; then
    fail_validation - <<'EOF'
SBOM file `~/rhhi-demo.spdx` was not found.

Review **“Step 2: Generate a Machine-Readable SPDX SBOM”**, then validate again.
EOF
fi

if ! jq empty "$SBOM_FILE" > /dev/null 2>&1; then
    fail_validation - <<'EOF'
`~/rhhi-demo.spdx` is not valid JSON.

Review **“Step 2: Generate a Machine-Readable SPDX SBOM”**, then validate again.
EOF
fi

PKG_COUNT=$(jq '.packages | length' "$SBOM_FILE" 2>/dev/null)
if [ -z "$PKG_COUNT" ]; then
    fail_validation - <<'EOF'
The package count could not be read from `~/rhhi-demo.spdx`.

Review **“Step 3: Inspect the SBOM”**, then validate again.
EOF
fi

if [ "$PKG_COUNT" -le 20 ]; then
    fail_validation "The SBOM contains $PKG_COUNT packages; expected more than 20." \
      "" "Review **“Step 2: Generate a Machine-Readable SPDX SBOM”**, then validate again."
fi

echo "PASS: SBOM found at ~/rhhi-demo.spdx with $PKG_COUNT packages" >> /tmp/progress.log
exit 0
