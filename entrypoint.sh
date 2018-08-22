#!/usr/bin/env bash
set -euo pipefail

cat <<EOF > /etc/jupyter/ssl.key
$SSL_KEY
EOF

cat <<EOF > /etc/jupyter/ssl.crt
$SSL_CERT
EOF

sed -i -e "s%__JPYNB_S3_ACCESS_KEY_ID__%${JPYNB_S3_ACCESS_KEY_ID}%g" /etc/jupyter/jupyter_notebook_config.py
sed -i -e "s%__JPYNB_S3_SECRET_ACCESS_KEY__%${JPYNB_S3_SECRET_ACCESS_KEY}%g" /etc/jupyter/jupyter_notebook_config.py
sed -i -e "s%__JPYNB_S3_REGION_NAME__%${JPYNB_S3_REGION_NAME}%g" /etc/jupyter/jupyter_notebook_config.py
sed -i -e "s%__JPYNB_S3_BUCKET_NAME__%${JPYNB_S3_BUCKET_NAME}%g" /etc/jupyter/jupyter_notebook_config.py

docker pull $DOCKER_SPAWNER_IMAGE
jupyterhub --config=/etc/jupyter/jupyterhub_config.py
