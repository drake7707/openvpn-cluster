#!/bin/bash

docker ps -a -q --filter=label="vpn-cluster" | while read container_id; do
    echo "Removing container:" "${container_id}"
    docker rm -fv "${container_id}"
done

docker network rm m1network
docker network rm m2network
docker network rm m3network
docker network rm w1network
docker network rm w2network
docker network rm w3network

rm -rf m1 m2 m3
