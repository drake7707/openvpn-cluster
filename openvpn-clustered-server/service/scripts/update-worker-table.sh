#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

# This script updates or creates an entry in the worker table in etcd 
# for a worker

action="${1:-}"
worker_name="${2:-}"


if [[ -z "${action}" ]]; then
  echo "Action is required, please specify connect or disconnect" 1>&2
  exit 1
fi

if [[ -z "${worker_name}" ]]; then
  echo "Worker name is required" 1>&2
  exit 1
fi

worker_entry=$(./etcdget.sh "/vpn/workers/${worker_name}")

if [[ "${action}" == "connect" ]]; then

  own_master_ip=$(./get-vpn-ip.sh)
  masters=$(./etcdget.sh "/vpn/masters/")
  # master_number;public_ip;public_port;vpn_subnet;vpn_gateway;last_updated

  # look up what the own master id is based on the subnet
  own_master_id=
  IFS=$'\n' read -d '' -ra master_lines <<< "${masters}" || true
  for line in "${master_lines[@]}"; do
     echo "$line"
     IFS=";" read -ra line_parts <<< "${line}"
  
     master_nr="${line_parts[0]}"
     vpn_subnet="${line_parts[3]}"
     vpn_gateway="${line_parts[4]}"
  
     if [[ "${vpn_gateway}" == "${own_master_ip}" ]]; then
       own_master_id=${master_nr}
       break
     fi
  done

  if [[ -z ${own_master_id} ]]; then
    echo "Unable to determine own master id"
    exit 1
  fi

  worker_base_address=$(./etcdget.sh "/vpn/config/worker_base_ip")


  # import the helper functions necessary for building the worker ip
  DIR="${BASH_SOURCE%/*}"
  if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
  source "${DIR}/helper.sh"

  nr=
  ip=
  on_master=${own_master_id}

  if [[ -z "$worker_entry" ]]; then
    # worker is not in the workers table
    # give the worker a new ip address
    workers=$(./etcdgetkeys.sh "/vpn/workers/")
    worker_count=$(echo "$workers" | grep -cv "^$" || true)
    nr=${worker_count}
    nr=$((nr+1))
    ip=$(helper::add_to_ip "${worker_base_address}" "${nr}")
  else
    IFS=";" read -ra line_parts <<< "${worker_entry}"
    nr="${line_parts[0]}"
    ip="${line_parts[3]}"
  fi

  last_updated=$(date "+%Y-%m-%dT%H:%M:%S")
  # worker_number;worker_name;connected-to-master;worker-ip;last-updated
  worker_entry="${nr};${worker_name};${on_master};${ip};${last_updated}"

  # TODO: this is NOT atomic, it's possible another OpenVPN server claimed the worker number during the get and this put!. This needs to be done in a transaction!
  ./etcdset.sh "/vpn/workers/${worker_name}" "${worker_entry}"

elif [[ "${action}" == "disconnect" ]]; then
  # Write -1 into the worker entry as 'on master'

  if [[ -z "${worker_entry}" ]]; then
    echo "Worker entry not found for worker ${worker_name}" 1>&2
    exit 1
  fi

  IFS=";" read -ra line_parts <<< "${worker_entry}"
  nr="${line_parts[0]}"
  ip="${line_parts[3]}"
  on_master="-1"

  last_updated=$(date "+%Y-%m-%dT%H:%M:%S")

  worker_entry="${nr};${worker_name};${on_master};${ip};${last_updated}"
  ./etcdset.sh "/vpn/workers/${worker_name}" "${worker_entry}"

fi