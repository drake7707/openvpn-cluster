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

  # Nothing here can be done that is blocking so the worker data is fetched with the help of the client up script instead

  # push the worker name because it's not included in the env vars in client up
  echo "push \"setenv-safe WORKER_NAME ${client_name#worker-}\" " > $tmpCCDFile

elif [[ "${client_name}" != "${client_name#master-}" ]]; then
  # this client is a foreign master

  # update the route for the master
  master_name=${client_name#master-}
  
  # ifconfig_pool_remote_ip is a env set by openvpn
  cd /service/scripts
  ./update-master-route.sh "${master_name}" "${ifconfig_pool_remote_ip}" &
 
  # TODO: if for some reason adding master route fails, then it MUST disconnect the client, otherwise the master routing is in an inconsistent state
  # This must be done through the management API as it runs in a background process to not block the entire tunnel

else 
  # this client is something else, probably a client config for an admin
  true
fi
