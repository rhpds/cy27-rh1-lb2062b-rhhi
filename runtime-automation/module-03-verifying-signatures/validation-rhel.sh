#!/bin/sh
echo "Validating module-03" >> /tmp/progress.log

if [ ! -f /home/rhel/hi-python.sig ]; then
    echo "FAIL: hi-python.sig not found" >> /tmp/progress.log
    echo "HINT: Verify the hi/python:3.12 signature with cosign using the Red Hat public key URL" >> /tmp/progress.log
    exit 1
fi

if [ ! -f /home/rhel/ubi-latest.sig ]; then
    echo "FAIL: ubi-latest.sig not found" >> /tmp/progress.log
    echo "HINT: Verify the ubi10/ubi:latest signature with cosign using the local RHEL signing key" >> /tmp/progress.log
    exit 1
fi

echo "PASS: Both signature output files exist" >> /tmp/progress.log
exit 0
