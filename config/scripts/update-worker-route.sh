#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
set -x

own_master_ip=$(./get-vpn-ip.sh)

IFS=

source ./update-worker-routes-master-helper.sh

line=$1
source ./update-worker-routes-process-route.sh

