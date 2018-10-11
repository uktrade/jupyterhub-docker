#!/bin/sh

# Based on https://github.com/docker/distribution-library-image/, but generating a
# self-signed certificate on launch

set -e

openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj /CN=selfsigned \
    -keyout /ssl.key \
    -out /ssl.crt
chmod 0600 /ssl.key /ssl.crt

case "$1" in
    *.yaml|*.yml) set -- registry serve "$@" ;;
    serve|garbage-collect|help|-*) set -- registry "$@" ;;
esac

exec "$@"
