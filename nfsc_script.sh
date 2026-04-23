#!/bin/bash

set -e

apt install -y nfs-common

mkdir -p /mnt

cat <<EOF >> /etc/fstab
192.168.0.7:/srv/share /mnt nfs vers=3,noauto,x-systemd.automount 0 0
EOF

systemctl daemon-reload
systemctl restart remote-fs.target
