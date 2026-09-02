#!/bin/sh
echo "Solving module-04: Push and Generate Keys" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
. ~/.bashrc
podman tag rhhi-demo:hardened ${REGISTRY}/rhhi-demo:hardened
podman push --digestfile /home/rhel/image.digest ${REGISTRY}/rhhi-demo:hardened
export COSIGN_PASSWORD=""
cd ~
cosign generate-key-pair
RHEL_EOF
echo "module-02 solve complete" >> /tmp/progress.log
