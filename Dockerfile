ARG VER=0.9
FROM jupyterhub/jupyterhub:$VER

ENV DOCKER_VER=18.03.1
RUN pip3 install jupyter noteboook oauthenticator dockerspawner
RUN curl -Lfs "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VER}-ce.tgz" | tar -xzvf - -C /usr/bin --strip-components=1

COPY config/jupyterhub_config.py /etc/jupyterhub_config.py
COPY config/spawner-init.sh /spawner-init.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
