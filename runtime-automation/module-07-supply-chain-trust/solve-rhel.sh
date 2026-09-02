#!/bin/sh
echo "Solving module-07: Establish Supply Chain Trust" >> /tmp/progress.log

. /home/rhel/.bashrc 2>/dev/null || true

# Download the attestation bundle Red Hat publishes for the vendor image
runuser -l rhel -c "/usr/local/bin/cosign download attestation --output-file /home/rhel/redhat.sbom registry.access.redhat.com/hi/python:3.12" >> /tmp/progress.log 2>&1

# Isolate the SLSA v0.2 provenance envelope and save the decoded in-toto statement
runuser -l rhel -c "jq -r 'select((.payload | @base64d | fromjson | .predicateType) == \"https://slsa.dev/provenance/v0.2\") | .payload | @base64d | fromjson' /home/rhel/redhat.sbom > /home/rhel/python-slsa.json" >> /tmp/progress.log 2>&1

echo "module-07 solve complete" >> /tmp/progress.log
