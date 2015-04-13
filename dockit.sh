#!/usr/bin/env bash

if [$1 == "--with-build-image"]; then
  docker build -t ralch-blog .
fi

docker run --name blog -e VIRTUAL_HOST=blog.ralch.com --restart="always" -d ralch-blog 

