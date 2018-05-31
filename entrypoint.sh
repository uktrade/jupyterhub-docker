#!/usr/bin/env bash

export BIND_URL=http://$(hostname -I | cut -d' ' -f1):8000

jupyterhub --config=/etc/jupyter/jupyterhub_config.py
