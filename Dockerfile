ARG VER=0.9
FROM jupyterhub/jupyterhub:$VER

RUN pip3 install oauthenticator dockerspawner

COPY config/jupyterhub_config.py /etc/jupyterhub_config.py
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
