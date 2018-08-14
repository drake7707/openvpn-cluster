#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
set -x


set

client_name=${X509_0_CN}

echo "Client ${client_name} has connected"

if [[ "${client_name}" != "${client_name#worker-}" ]]; then # if the prefix is able to be removed, it has worker- as prefix and the string won't be the same
  # this client is a worker

  # look up the worker in the store to determine its assigned ip address
  worker_ip="..."

  # update the etcd worker table
  cd /config/scripts
  /config/scripts/update-worker-table.sh ${client_name#worker-}

  # update the worker routes
  cd /config/scripts
  /config/scripts/update-worker-routes.sh ${client_name#worker-}

elif [[ "${client_name}" != "${client_name#master-}" ]]; then
  # this client is a foreign master

  # update the route for the master

  cd /config/scripts 
  master_name=${client_name#master-}
  # ifconfig_pool_remote_ip is a env set by openvpn
  /config/scripts/update-master-route.sh "${master_name}" "${ifconfig_pool_remote_ip}"

else 
  # this client is something else, probably a client config for an admin
  true
fi
