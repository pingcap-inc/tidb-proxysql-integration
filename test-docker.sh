#!/bin/sh

docker compose up -d
./run-test.sh
docker compose stop