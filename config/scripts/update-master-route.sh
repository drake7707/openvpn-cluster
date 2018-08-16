#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
set -x

# This scripts adds a route for the master that joined the subnet
# by looking the master up in etcd

master_name=$1
master_ip_in_subnet=$2


# must skip consensus because etcd might be unhealthy by master that has joined
master_entry=$(./etcdget.sh --skip-consensus "/vpn/masters/${master_name}")

# master_number;public_ip;public_port;vpn_subnet;vpn_gateway;last_updated

if [[ -z "${master_entry}" ]]; then
  echo "There is no master entry for ${master_name}, unable to add the correct route"
  exit 1
fi

IFS=";" read -ra line_parts <<< "${master_entry}"
master_vpn_subnet=${line_parts[3]}

ip r r "${master_vpn_subnet}" via "${master_ip_in_subnet}" dev tap0

