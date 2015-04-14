#!/usr/bin/env bash

set -x

HOST_DIR=/var/vcap/jobs/ralch-blog
CONTAINER_DIR=/var/vcap/jobs/ralch-blog
NGINX_HOST=blog.ralch.com
NGINX_PORT=1313
CONTAINER_ENTRYPOINT="./ralch-blog-server -port=$NGINX_PORT"

docker run -v $HOST_DIR:$CONTAINER_DIR \
           -w $CONTAINER_DIR \
           -e VIRTUAL_HOST=$NGINX_HOST \
           -e VIRTUAL_PORT=$NGINX_PORT \
           --expose $NGINX_PORT \
           --entrypoint="$CONTAINER_ENTRYPOINT" \
           --restart="always" \
           --name blog \
           -d busybox 

