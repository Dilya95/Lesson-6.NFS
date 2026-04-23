#!/bin/bash

set -e

apt install -y nfs-kernel-server

mkdir -p /srv/share/upload

chown -R nobody:nogroup /srv/share
chmod 0777 /srv/share/upload

cat <<EOF > /etc/exports
/srv/share 192.168.0.3/32(rw,sync,root_squash)
EOF

exportfs -r
systemctl enable nfs-server
systemctl restart nfs-server
