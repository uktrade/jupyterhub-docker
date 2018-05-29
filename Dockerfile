ARG VER=0.9
FROM jupyterhub/jupyterhub:$VER

ENV DOCKER_VER=18.03.1
RUN pip3 install oauthenticator dockerspawner
RUN curl -Lfs "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VER}-ce.tgz" | tar -xzvf - -C /usr/bin --strip-components=1

COPY config/jupyterhub_config.py /etc/jupyter/jupyterhub_config.py
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
