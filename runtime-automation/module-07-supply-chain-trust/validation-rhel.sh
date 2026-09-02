#!/bin/sh
echo "Validating module-07" >> /tmp/progress.log

if [ ! -f /home/rhel/redhat.sbom ]; then
    echo "FAIL: redhat.sbom not found" >> /tmp/progress.log
    echo "HINT: Download the vendor attestation with 'cosign download attestation --output-file redhat.sbom registry.access.redhat.com/hi/python:3.12'" >> /tmp/progress.log
    exit 1
fi

# Confirm the SLSA v0.2 provenance envelope is present and its builder id is retrievable
BUILDER=$(runuser -l rhel -c "jq -r 'select((.payload | @base64d | fromjson | .predicateType) == \"https://slsa.dev/provenance/v0.2\") | .payload | @base64d | fromjson | .predicate.builder.id' /home/rhel/redhat.sbom" 2>>/tmp/progress.log)

if [ -z "$BUILDER" ]; then
    echo "FAIL: SLSA provenance predicate not found in the vendor attestation" >> /tmp/progress.log
    echo "HINT: Isolate the SLSA v0.2 envelope from redhat.sbom as shown in the module" >> /tmp/progress.log
    exit 1
fi

echo "PASS: SLSA provenance found (builder: ${BUILDER})" >> /tmp/progress.log
exit 0
