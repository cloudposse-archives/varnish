#!/bin/bash

echo ${VARNISH_SECRET} > /etc/varnish/secret

set -x

OPS=()
OPS=("-j none")
OPS+=("-F")
OPS+=("-a :80")
OPS+=("-T :6082")
OPS+=("-S /etc/varnish/secrets/secret")
OPS+=("-p thread_pool_min=${VARNISH_THREAD_POOL_MIN}")
OPS+=("-p thread_pools=${VARNISH_THREAD_POOLS}")
OPS+=("-p cli_timeout=${VARNISH_CLI_TIMEOUT}")
OPS+=("-p first_byte_timeout=${VARNISH_BACKEND_FIRST_BYTE_TIMEOUT}")
OPS+=("-p connect_timeout=${VARNISH_BACKEND_CONNECT_TIMEOUT}")
OPS+=("-p between_bytes_timeout=${VARNISH_BACKEND_BETWEEN_BYTES_TIMEOUT}")
OPS+=("-s file,/var/lib/varnish/varnish_storage.bin,${VARNISH_STORAGE}")

if [[ -a /etc/varnish/configs/default.vcl ]]; then

OPS+=("-f  /etc/varnish/configs/default.vcl")

else

OPS+=("-b ${VARNISH_BACKEND_HOST}:${VARNISH_BACKEND_PORT}")

fi

varnishd ${OPS[*]};

