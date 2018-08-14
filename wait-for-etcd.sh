#!/bin/bash

container_name=$1

function wait-for-etcd {
  local n=1
  local ntries=60
  while true; do

    if docker exec -i ${container_name} etcdctl cluster-health 2>/dev/null; then
      if ((--n == 0)); then
        echo "[done]" >&2
        break
      fi
    else
      n=3
    fi
    if ((--ntries == 0)); then
      echo "Error waiting for etcd to come up"
      exit 1
    fi
    echo -n "." >&2
    sleep 1
  done
}

wait-for-etcd
