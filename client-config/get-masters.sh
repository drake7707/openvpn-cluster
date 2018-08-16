#!/bin/bash

set -x

mkdir -p /data
route_vpn_gateway=$(cat /data/vpn_gateway)

masters=$(wget -q -O - http://${route_vpn_gateway}:1500/masters)

if [[ "$?" -eq 0 ]]; then


  # master_number;public_ip;public_port;vpn_subnet;vpn_gateway;last_updated
  # e.g
  #  1 ; 10.10.127.41 ; 1194 ; 192.168.1.0/24 ; 192.168.1.1 ; `date "+%Y-%m-%dT%H:%M:%S"`

  remote_args="--remote-random"

  IFS=$'\n' read -d '' -r -a master_lines <<< "${masters}" || true
  for line in "${master_lines[@]}"; do
    echo "$line"
    IFS=";" read -ra line_parts <<< "${line}"

    master_nr="${line_parts[0]}"
    public_ip="${line_parts[1]}"
    public_port="${line_parts[2]}"

    remote_args="${remote_args} --remote ${public_ip} ${public_port}"
  done

  echo "${remote_args}" > /data/remote_args
fi



