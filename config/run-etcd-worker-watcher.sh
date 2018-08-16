#!/bin/bash
if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

trap "exit" INT

while true; do

  cd /config/scripts
  ./etcdwatch.sh "/vpn/workers/" './update-worker-route.sh "${ETCD_WATCH_VALUE}"'

  sleep 1
  echo "etcd watch on /vpn/workers/ was stopped, restarting.."

done
