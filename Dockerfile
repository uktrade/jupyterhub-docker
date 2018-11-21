FROM alpine:3.8

ENV \
	LC_ALL=en_US.UTF-8 \
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8

RUN \
	apk add --no-cache \
		libcurl=7.61.1-r1 \
		npm=8.11.4-r0 \
		openssl=1.0.2p-r0 \
		py-cryptography=2.1.4-r1 \
		py-psycopg2=2.7.5-r0 \
		py3-curl=7.43.0-r5 \
		python3=3.6.6-r0 \
		tini=0.18.0-r0 && \
	python3 -m ensurepip && \
	pip3 install pip==18.01 && \
	pip3 install \
		fargatespawner==0.0.19 \
		jupyterhub==0.9.2 \
		oauthenticator==0.8.0 && \
	npm install -g \
		configurable-http-proxy@3.1.1 && \
	npm cache clean --force

COPY config/jupyterhub_config.py /etc/jupyter/jupyterhub_config.py
COPY config/access.py /usr/lib/python3.6/site-packages/access.py
COPY config/utils.py /usr/lib/python3.6/site-packages/utils.py

ENTRYPOINT ["tini", "--"]
CMD ["jupyterhub", "--config=/etc/jupyter/jupyterhub_config.py"]

RUN adduser -S jovyan
USER jovyan
