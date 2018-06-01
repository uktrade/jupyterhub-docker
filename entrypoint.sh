#!/usr/bin/env bash

#debug
echo -e $SSL_KEY
echo -e $SSL_CERT

echo -e $SSL_KEY > /etc/jupyter/ssl.key
echo -e $SSL_CERT > /etc/jupyter/ssl.crt

jupyterhub --config=/etc/jupyter/jupyterhub_config.py
