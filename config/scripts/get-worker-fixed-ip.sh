#!/bin/bash

worker_name=${1:-}

if [[ -z "${worker_name}" ]]; then
  echo "Worker name is not specified" 2>&1
  exit 1
fi

worker_entry=$(./etcdget.sh "/vpn/workers/${worker_name}")

IFS=";" read -ra line_parts <<< "${worker_entry}"

ip="${line_parts[3]}"

echo ${ip}

