#!/bin/sh

set -e

dnsmasq -k \
	--user=root \
	--no-hosts \
	--no-resolv \
	--log-queries \
	--log-facility=- \
	--server=/notebook.uktrade.io/${DNS_SERVER} \
	--server=/amazonaws.com/${DNS_SERVER}
