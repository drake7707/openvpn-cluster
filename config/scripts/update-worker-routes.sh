#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

IFS=

source ./update-worker-routes-master-helper.sh

workers=$(./etcdget.sh "/vpn/workers/")

# worker_number;worker_name;connected-to-master;worker-ip;last-updated
IFS=$'\n' read -d '' -r -a worker_lines <<< "${workers}" || true

echo "lines: ${#worker_lines[@]}"

for line in "${worker_lines[@]}"; do

   source ./update-worker-routes-process-route.sh

done
