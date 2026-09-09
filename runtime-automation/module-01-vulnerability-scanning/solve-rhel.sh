#!/bin/sh
echo "Solving module-01" >> /tmp/progress.log

RHEL_UID=$(id -u rhel)
runuser -u rhel -- env \
  XDG_RUNTIME_DIR=/run/user/${RHEL_UID} \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${RHEL_UID}/bus \
  systemctl --user enable --now podman.socket

