#!/usr/bin/env bash
set -euo pipefail

# The AWS console task definition editor converts \n, a single byte newline character,
# into \\n, which is the two bytes "\n", so we do the reverse here.
echo "$SSL_KEY" | sed 's/\\n/\n/g' > /usr/local/etc/jupyter/ssl.key
echo "$SSL_CERT" | sed 's/\\n/\n/g' > /usr/local/etc/jupyter/ssl.crt

rsync -auzv /usr/local/etc/jupyter/ /etc/jupyter/

# hub_ip is the interface that the hub listens on, 0.0.0.0 == all
# hub_connect_ip is the IP that _other_ services will connect to the hub on, i.e. the current private IP address
jupyterhub --config=/etc/jupyter/jupyterhub_config.py --JupyterHub.hub_ip="0.0.0.0" --JupyterHub.hub_connect_ip="$(curl -Lfs http://169.254.169.254/latest/meta-data/local-ipv4)"
