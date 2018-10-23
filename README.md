# jupyterhub-docker

![JupyterHub components and connections](jupyterhub-components-and-connections.png)

# Building & Pushing Docker Images to Quay

## JupyterHub

```bash
docker build -t jupyterhub . && \
docker tag jupyterhub:latest  quay.io/uktrade/jupyterhub:latest && \
docker push quay.io/uktrade/jupyterhub:latest
```

## Single user notebook server

```bash
docker build -t jupyterhub-singleuser -f Dockerfile-singleuser . && \
docker tag jupyterhub-singleuser:latest  quay.io/uktrade/jupyterhub-singleuser:latest && \
docker push quay.io/uktrade/jupyterhub-singleuser:latest
```

## Docker pull-through cache

To limit egress from the notebook servers, we only allow in-VPC connections. For the docker images themselves, we run a registry that proxies read access to certain images in Quay.

```bash
docker build -t jupyterhub-registry -f Dockerfile-registry . && \
docker tag jupyterhub-registry:latest  quay.io/uktrade/jupyterhub-registry:latest && \
docker push quay.io/uktrade/jupyterhub-registry:latest
```

## Logstash

For logs from the notebook servers, we run a logstash instance inside the VPC that proxies to our public logstash service.

```bash
docker build -t jupyterhub-logstash -f Dockerfile-logstash . && \
docker tag jupyterhub-logstash:latest  quay.io/uktrade/jupyterhub-logstash:latest && \
docker push quay.io/uktrade/jupyterhub-logstash:latest
```
