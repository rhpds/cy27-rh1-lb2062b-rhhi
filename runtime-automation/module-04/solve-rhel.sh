#!/bin/sh
echo "Solving module-04: Push and Generate Keys" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
. ~/.bashrc
podman tag rhhi-demo:hardened ${REGISTRY}/rhhi-demo:hardened
podman push --digestfile /home/rhel/image.digest ${REGISTRY}/rhhi-demo:hardened
export COSIGN_PASSWORD=""
cd ~
cosign generate-key-pair
# --preserve-digests copies the manifest verbatim so the mirror keeps Red Hat's exact
# index digest (without it skopeo re-serializes the index and the digest changes).
# --authfile keeps skopeo off its unreadable default path under runuser -l (no
# XDG_RUNTIME_DIR). Registry is anonymous, so a missing authfile is harmless.
skopeo copy --all --preserve-digests --remove-signatures --authfile /home/rhel/.config/containers/auth.json --digestfile /home/rhel/python.digest docker://registry.access.redhat.com/hi/python:3.12 docker://${REGISTRY}/python:3.12
RHEL_EOF
echo "module-04 solve complete" >> /tmp/progress.log
