ARG JUPYTERHUB_VER=0.9.2
FROM jupyterhub/jupyterhub:$JUPYTERHUB_VER

RUN pip install --upgrade pip fargatespawner==0.0.9 oauthenticator psycopg2-binary

COPY config/jupyterhub_config.py /etc/jupyter/jupyterhub_config.py
COPY config/spawner-init.sh /etc/jupyter/spawner-init.sh
COPY entrypoint.sh /entrypoint.sh

COPY config/env_utils.py /opt/conda/lib/python3.6/site-packages/env_utils.py

ENTRYPOINT ["/entrypoint.sh"]
