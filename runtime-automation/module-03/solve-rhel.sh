#!/bin/sh
echo "Solving module-03: Verify Published Signatures" >> /tmp/progress.log

# Verify hi/python:3.12 signature using the Red Hat release key 3 URL
/usr/local/bin/cosign verify --insecure-ignore-tlog \
  --output-file /home/rhel/hi-python.sig \
  --key https://security.access.redhat.com/data/63405576.txt \
  registry.access.redhat.com/hi/python:3.12

# Verify UBI image signature using the local signing key shipped with RHEL
/usr/local/bin/cosign verify --insecure-ignore-tlog \
  --output-file /home/rhel/ubi-latest.sig \
  --key /etc/pki/sigstore/SIGSTORE-redhat-release3 \
  registry.access.redhat.com/ubi10/ubi:latest

jq -r '.[0].optional' /home/rhel/hi-python.sig

echo "module-03 solve complete" >> /tmp/progress.log
