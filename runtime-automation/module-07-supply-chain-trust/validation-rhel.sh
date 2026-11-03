#!/bin/sh
echo "Validating module-07" >> /tmp/progress.log

if [ ! -f /home/rhel/redhat.sbom ]; then
    fail_validation - <<'EOF'
Vendor attestation file `~/redhat.sbom` was not found.

Review **“Download the Vendor's Attestations”**, then validate again.
EOF
fi

# Confirm the SLSA v0.2 provenance envelope is present and its builder id is retrievable
BUILDER=$(runuser -l rhel -c "jq -r 'select((.payload | @base64d | fromjson | .predicateType) == \"https://slsa.dev/provenance/v0.2\") | .payload | @base64d | fromjson | .predicate.builder.id' /home/rhel/redhat.sbom" 2>>/tmp/progress.log)

if [ -z "$BUILDER" ]; then
    fail_validation - <<'EOF'
An SLSA provenance builder ID could not be read from `~/redhat.sbom`.

Review **“Isolate the SLSA Provenance”**, then validate again.
EOF
fi

echo "PASS: SLSA provenance found (builder: ${BUILDER})" >> /tmp/progress.log
exit 0
