#!/usr/bin/env bash

set -euo pipefail
#debug
env | sort

cat <<EOF >/etc/jupyter/ssl.key
$SSL_KEY
EOF

cat <<EOF > /etc/jupyter/ssl.crt
$SSL_CERT
EOF

cat /etc/jupyter/ssl.key
cat /etc/jupyter/ssl.crt

jupyterhub --config=/etc/jupyter/jupyterhub_config.py
