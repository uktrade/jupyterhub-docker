#!/usr/bin/env bash

#debug
env | sort

echo -e $SSL_KEY > /etc/jupyter/ssl.key
echo -e $SSL_CERT > /etc/jupyter/ssl.crt

cat /etc/jupyter/ssl.key
cat /etc/jupyter/ssl.crt

jupyterhub --config=/etc/jupyter/jupyterhub_config.py
