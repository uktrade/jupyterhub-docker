#!/usr/bin/env bash
set -euo pipefail

cat <<EOF > /usr/local/etc/jupyter/ssl.key
$SSL_KEY
EOF

cat <<EOF > /usr/local/etc/jupyter/ssl.crt
$SSL_CERT
EOF

sed -i -e "s%__JPYNB_S3_ACCESS_KEY_ID__%${JPYNB_S3_ACCESS_KEY_ID}%g" /usr/local/etc/jupyter/jupyter_notebook_config.py
sed -i -e "s%__JPYNB_S3_SECRET_ACCESS_KEY__%${JPYNB_S3_SECRET_ACCESS_KEY}%g" /usr/local/etc/jupyter/jupyter_notebook_config.py
sed -i -e "s%__JPYNB_S3_REGION_NAME__%${JPYNB_S3_REGION_NAME}%g" /usr/local/etc/jupyter/jupyter_notebook_config.py
sed -i -e "s%__JPYNB_S3_BUCKET_NAME__%${JPYNB_S3_BUCKET_NAME}%g" /usr/local/etc/jupyter/jupyter_notebook_config.py

cp -arf /usr/local/etc/jupyter/* /etc/jupyter/

docker pull $DOCKER_SPAWNER_IMAGE
jupyterhub --config=/etc/jupyter/jupyterhub_config.py
