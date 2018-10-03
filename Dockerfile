ARG JUPYTERHUB_VER=0.9.2
FROM jupyterhub/jupyterhub:$JUPYTERHUB_VER

RUN pip install --upgrade \
	pip==18.0 \
	fargatespawner==0.0.12 \
	aiopg==0.15.0 \
	oauthenticator==0.8.0 \
	psycopg2-binary==2.7.5

COPY config/jupyterhub_config.py /etc/jupyter/jupyterhub_config.py
COPY entrypoint.sh /entrypoint.sh

COPY config/database_access.py /opt/conda/lib/python3.6/site-packages/database_access.py
COPY config/env_utils.py /opt/conda/lib/python3.6/site-packages/env_utils.py

ENTRYPOINT ["/entrypoint.sh"]
