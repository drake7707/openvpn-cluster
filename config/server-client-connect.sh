#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
set -x


tmpCCDFile=$1

client_name=${X509_0_CN}

echo "Client ${client_name} has connected"

if [[ "${client_name}" != "${client_name#worker-}" ]]; then # if the prefix is able to be removed, it has worker- as prefix and the string won't be the same
  # this client is a worker

  # Scripts that access etcdctl must run in the background
  # because etcdctl will use the OpenVPN tunnel for fetching/setting data
  # and OpenVPN is sadly single threaded, which means the entire server is blocked while this
  # script is running...
 
  # TODO: if for some reason the scripts return a non zero exit code
  # go and kill the client through the --management thing
  # otherwise the client will stay connected but the cluster data is not updated 

  # update the etcd worker table
#  cd /config/scripts
#  /config/scripts/update-worker-table.sh connect ${client_name#worker-} &

  # update the worker routes
#  cd /config/scripts
#  /config/scripts/update-worker-routes.sh &

  # I can't really do this either because it would need to be in sync and this script is blocking the etcd communication
  #echo "push \"setenv-safe WORKER_IP 5.0.0.3\" " > $tmpCCDFile
  echo "push \"setenv-safe WORKER_NAME ${client_name#worker-}\" " > $tmpCCDFile

   true

elif [[ "${client_name}" != "${client_name#master-}" ]]; then
  # this client is a foreign master

  # update the route for the master

  cd /config/scripts 
  master_name=${client_name#master-}
  # ifconfig_pool_remote_ip is a env set by openvpn
  /config/scripts/update-master-route.sh "${master_name}" "${ifconfig_pool_remote_ip}" &

else 
  # this client is something else, probably a client config for an admin
  true
fi
