#!/usr/bin/env bash

docker build -t ralch-blog .
docker run --name blog -p 1313:1313 --restart="always" -d ralch-blog 

