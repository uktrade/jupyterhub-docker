#!/usr/bin/env bash

echo -e $SSL_KEY > /etc/jupyter/ssl.key
echo -e $SSL_CERT > /etc/jupyter/ssl.crt

jupyterhub --config=/etc/jupyter/jupyterhub_config.py
