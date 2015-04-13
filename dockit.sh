#!/usr/bin/env bash

ARG=$1

if [ -z "$ARG" ]; then
  ARG="-no-image"
fi

if [ $ARG == "--with-build-image" ]; then
  docker build -t ralch/blog .
fi

docker run -e VIRTUAL_HOST=ralch.com,www.ralch.com -e VIRTUAL_PORT=1314 --restart="always" --name blog -d ralch/blog

