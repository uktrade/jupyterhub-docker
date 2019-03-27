FROM alpine:3.8

ENV \
	LC_ALL=en_US.UTF-8 \
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8

RUN \
	apk add --no-cache --virtual .build-deps \
		build-base=0.5-r1 \
		git=2.18.1-r0 && \
	apk add --no-cache \
		libcurl=7.61.1-r2 \
		libffi-dev=3.2.1-r4 \
		libffi=3.2.1-r4 \
		npm=8.14.0-r0 \
		openssl-dev=1.0.2r-r0 \
		openssl=1.0.2r-r0 \
		py-cryptography=2.1.4-r1 \
		py-psycopg2=2.7.5-r0 \
		py3-curl=7.43.0-r5 \
		python3-dev=3.6.6-r0 \
		python3=3.6.6-r0 \
		tini=0.18.0-r0 && \
	# JupyterHub install requires "python"
	ln -s /usr/bin/python3 /usr/bin/python && \
	python3 -m ensurepip && \
	pip3 install pip==18.01 && \
	pip3 install \
		fargatespawner==0.0.22 \
		oauthenticator==0.8.0 \
		-e git+git://github.com/jupyterhub/jupyterhub@342f40c8d7b17d500c86b236a0c817726141b496#egg=jupyterhub && \
	npm install -g \
		configurable-http-proxy@3.1.1 && \
	npm cache clean --force && \
	apk del .build-deps

COPY config/jupyterhub_config.py /etc/jupyter/jupyterhub_config.py
COPY config/access.py /usr/lib/python3.6/site-packages/access.py
COPY config/utils.py /usr/lib/python3.6/site-packages/utils.py

ENTRYPOINT ["tini", "--"]
CMD ["jupyterhub", "--config=/etc/jupyter/jupyterhub_config.py"]

RUN adduser -S jovyan
USER jovyan
