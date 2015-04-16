#!/usr/bin/env bash

set -x

#HOST_DIR=/var/vcap/jobs/ralch-web
HOST_DIR=/Volumes/Macintosh-HD/Users/ralch/Projects/ralch-blog/web/public
CONTAINER_DIR=/var/www
NGINX_HOST=blog.ralch.com
NGINX_PORT=1313

docker run -v $HOST_DIR:$CONTAINER_DIR \
           -w $CONTAINER_DIR \
           -e VIRTUAL_HOST=$NGINX_HOST \
           -e VIRTUAL_PORT=$NGINX_PORT \
           --expose $NGINX_PORT \
           --restart="always" \
           --name web \
           -d grape -port $NGINX_PORT

