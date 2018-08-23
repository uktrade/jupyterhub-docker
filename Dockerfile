ARG JUPYTERHUB_VER=1.0
FROM jupyterhub/jupyterhub:$JUPYTERHUB_VER

RUN apt update && \
    apt-get install -y --no-install-recommends curl rsync && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV DOCKER_VER=18.03.1
RUN pip install oauthenticator dockerspawner psycopg2-binary
RUN wget -q -O - "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VER}-ce.tgz" | tar -xzvf - -C /usr/bin --strip-components=1

COPY config/jupyterhub_config.py /usr/local/etc/jupyter/jupyterhub_config.py
COPY config/jupyter_notebook_config.py /usr/local/etc/jupyter/jupyter_notebook_config.py
COPY config/spawner-init.sh /usr/local/etc/jupyter/spawner-init.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
