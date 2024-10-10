#!/bin/sh
set -ex

if [ $(find . -type d -empty -iname "unit") ]; then 
    git submodule update --init
fi

docker-compose down
docker build -t unit-perf --network host .
docker-compose up
