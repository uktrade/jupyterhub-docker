#!/usr/bin/env bash
set -euo pipefail

# The AWS console task definition editor converts \n, a single byte newline character,
# into \\n, which is the two bytes "\n", so we do the reverse here.
echo "$SSL_KEY" | sed 's/\\n/\n/g' > /usr/local/etc/jupyter/ssl.key
echo "$SSL_CERT" | sed 's/\\n/\n/g' > /usr/local/etc/jupyter/ssl.crt

sed -i -e "s%__JPYNB_S3_ACCESS_KEY_ID__%${JPYNB_S3_ACCESS_KEY_ID}%g" /usr/local/etc/jupyter/jupyter_notebook_config.py
sed -i -e "s%__JPYNB_S3_SECRET_ACCESS_KEY__%${JPYNB_S3_SECRET_ACCESS_KEY}%g" /usr/local/etc/jupyter/jupyter_notebook_config.py
sed -i -e "s%__JPYNB_S3_REGION_NAME__%${JPYNB_S3_REGION_NAME}%g" /usr/local/etc/jupyter/jupyter_notebook_config.py
sed -i -e "s%__JPYNB_S3_BUCKET_NAME__%${JPYNB_S3_BUCKET_NAME}%g" /usr/local/etc/jupyter/jupyter_notebook_config.py

rsync -auzv /usr/local/etc/jupyter/ /etc/jupyter/

$(aws ecr get-login --no-include-email --region eu-west-1)
docker pull $DOCKER_SPAWNER_IMAGE
jupyterhub --config=/etc/jupyter/jupyterhub_config.py --JupyterHub.bind_url="https://$(curl -Lfs http://169.254.169.254/latest/meta-data/local-ipv4):8000" --JupyterHub.hub_ip="$(curl -Lfs http://169.254.169.254/latest/meta-data/local-ipv4)"
