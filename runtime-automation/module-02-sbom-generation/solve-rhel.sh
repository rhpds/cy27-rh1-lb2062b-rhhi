#!/bin/sh
echo "Solving module-02" >> /tmp/progress.log

runuser -l rhel -c "syft rhhi-demo:hardened -o spdx-json=/home/rhel/rhhi-demo.spdx" >> /tmp/progress.log 2>&1
