#!/bin/bash
# 
# This script is run as root by certbot's post renew hook. It imports the renewed TLS certs into the backends app
set -euo pipefail

CERTDIR=${CERTDIR:-/etc/letsencrypt/live/backends.opensafely.org}
# the dokku user does not have permissions to cert files directly, so we have
# to do some trickery create a tar stream with a .crt and a .key file in, and
# pipe that to the dokku command.
tar --transform='flags=r;s|fullchain.pem|backends.crt|' \
    --transform='flags=r;s|privkey.pem|backends.key|' \
    --dereference -C "$CERTDIR" -c fullchain.pem privkey.pem | dokku certs:update backends
