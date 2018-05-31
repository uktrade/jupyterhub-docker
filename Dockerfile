ARG JUPYTERHUB_VER=0.9
FROM jupyterhub/jupyterhub:$JUPYTERHUB_VER

ENV DOCKER_VER=18.03.1
RUN pip3 install oauthenticator dockerspawner s3contents dask toolz
RUN curl -Lfs "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VER}-ce.tgz" | tar -xzvf - -C /usr/bin --strip-components=1

RUN conda config --system --prepend channels conda-forge && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    conda install --quiet --yes jupyter notebook jupyterlab && \
    conda clean -tipsy && \
    jupyter labextension install @jupyterlab/hub-extension && \
    npm cache clean --force

COPY config/jupyterhub_config.py /etc/jupyter/jupyterhub_config.py
COPY config/jupyter_notebook_config.py /etc/jupyter/jupyter_notebook_config.py
COPY config/spawner-init.sh /spawner-init.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
