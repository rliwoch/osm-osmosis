#!/usr/bin/env sh
set -eu

envsubst < renderd.conf.template > /etc/renderd.conf && cp /etc/renderd.conf /usr/local/etc/renderd.conf

exec "$@"
