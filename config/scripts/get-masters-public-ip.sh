#!/bin/bash

set -x

masters=$(./etcdget.sh "/vpn/masters/")

# master_number;public_ip;public_port;vpn_subnet;vpn_gateway;last_updated
# e.g
#  1 ; 10.10.127.41 ; 1194 ; 192.168.1.0/24 ; 192.168.1.1 ; `date "+%Y-%m-%dT%H:%M:%S"`

own_master_id=
IFS=$'\n' read -d '' -r -a master_lines <<< "${masters}" || true
for line in "${master_lines[@]}"; do
   IFS=";" read -ra line_parts <<< "${line}"

   master_nr="${line_parts[0]}"
   public_ip="${line_parts[1]}"
   public_port="${line_parts[2]}"

   echo "${master_nr};${public_ip};${public_port}"
done

