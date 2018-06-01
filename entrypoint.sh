#!/usr/bin/env bash
set -euo pipefail

cat <<EOF >/etc/jupyter/ssl.key
$SSL_KEY
EOF

cat <<EOF > /etc/jupyter/ssl.crt
$SSL_CERT
EOF

jupyterhub --config=/etc/jupyter/jupyterhub_config.py
