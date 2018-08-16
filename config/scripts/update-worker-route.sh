#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

# Updates a single worker route

line=${1:-}

if [[ -z "${line}" ]]; then
  echo "Worker entry line must be specified as first argument" 1>&2
  exit 1
fi 

own_master_ip=$(./get-vpn-ip.sh)

IFS=

source ./update-worker-routes-master-helper.sh

source ./update-worker-routes-process-route.sh

