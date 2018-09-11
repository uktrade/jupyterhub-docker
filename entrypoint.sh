#!/usr/bin/env bash
set -euo pipefail

openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
  -subj /CN=selfsigned \
  -keyout /etc/jupyter/ssl.key -out /etc/jupyter/ssl.crt

# hub_ip is the interface that the hub listens on, 0.0.0.0 == all
# hub_connect_ip is the IP that _other_ services will connect to the hub on, i.e. the current private IP address
jupyterhub --config=/etc/jupyter/jupyterhub_config.py --JupyterHub.hub_ip="0.0.0.0" --JupyterHub.hub_connect_ip="$(wget -qO- http://169.254.169.254/latest/meta-data/local-ipv4)"
