ARG JUPYTERHUB_VER=0.9.2
FROM jupyterhub/jupyterhub:$JUPYTERHUB_VER

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl rsync && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip oauthenticator psycopg2-binary

COPY config/jupyterhub_config.py /usr/local/etc/jupyter/jupyterhub_config.py
COPY config/spawner-init.sh /usr/local/etc/jupyter/spawner-init.sh
COPY entrypoint.sh /entrypoint.sh

COPY config/ecs_spawner.py /opt/conda/lib/python3.6/site-packages/ecs_spawner.py

ENTRYPOINT ["/entrypoint.sh"]
