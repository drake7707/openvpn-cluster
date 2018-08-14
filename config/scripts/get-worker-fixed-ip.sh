#!/bin/bash
set -x

worker_name=$1

worker_entry=$(./etcdget.sh "/vpn/workers/${worker_name}")
IFS=";" read -ra line_parts <<< "${worker_entry}"
ip="${line_parts[3]}"
echo ${ip}

