#!/bin/sh
echo "Validating module-01" >> /tmp/progress.log

RHEL_UID=$(id -u rhel)
if ! test -S /run/user/${RHEL_UID}/podman/podman.sock; then
    echo "FAIL: podman.socket is not active" >> /tmp/progress.log
    echo "HINT: Did you complete Step 1 to enable the podman socket?" >> /tmp/progress.log
    exit 1
fi

echo "PASS: podman.socket is active" >> /tmp/progress.log
exit 0
