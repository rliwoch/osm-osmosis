#!/usr/bin/env sh
set -eu

envsubst < renderd.conf.template > /etc/renderd.conf && cp /etc/renderd.conf /usr/local/etc/renderd.conf
service renderd start
service apache2 start
service apache2 reload
service apache2 reload

exec "$@"
