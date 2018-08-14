#!/bin/bash

# Registers this instance as a master in etcd 

master_name=$1
master_public_ip=$2
master_public_port=$3
master_vpn_subnet=$4
master_vpn_gateway=$5

# make sure to set workdir
cd /config/scripts/


master_entry=$(./etcdget.sh "/vpn/masters/${master_name}")

nr=

if [[ -z "${master_entry}" ]]; then
  # there is no master entry yet

  master_count=$(./etcdgetkeys.sh "/vpn/masters/" | grep -v "^$" | wc -l)
  nr=$((master_count+1))
else
  echo "Master is already registered"

  IFS=";" read -ra line_parts <<< "${master_entry}"
  nr="${line_parts[0]}"
fi


last_updated=$(date "+%Y-%m-%dT%H:%M:%S")

# master_number;public_ip;public_port;vpn_subnet;vpn_gateway;last_updated
master_entry="${nr};${master_public_ip};${master_public_port};${master_vpn_subnet};${master_vpn_gateway};${last_updated}"

./etcdset.sh "/vpn/masters/${master_name}" "${master_entry}"
