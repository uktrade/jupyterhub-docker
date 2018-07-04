#!/usr/bin/env bash
set -euo pipefail

cat <<EOF > /etc/jupyter/ssl.key
$SSL_KEY
EOF

cat <<EOF > /etc/jupyter/ssl.crt
$SSL_CERT
EOF

docker pull $DOCKER_SPAWNER_IMAGE
jupyterhub --config=/etc/jupyter/jupyterhub_config.py
