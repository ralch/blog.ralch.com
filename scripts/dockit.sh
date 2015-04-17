#!/usr/bin/env bash

set -x

HOST_DIR=/var/vcap/jobs/ralch-blog
WWW_DIR=/var/www
NGINX_HOST=blog.ralch.com
NGINX_PORT=1313

docker run -v $HOST_DIR:$WWW_DIR \
           -w $WWW_DIR \
           -e VIRTUAL_HOST=$NGINX_HOST \
           -e VIRTUAL_PORT=$NGINX_PORT \
           --expose $NGINX_PORT \
           --restart="always" \
           --name blog \
           -d ralch/grape -port $NGINX_PORT

