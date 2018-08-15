#!/bin/bash
set -x

trap "exit" INT

while true; do

  cd /config/scripts
  ./etcdwatch.sh './update-worker-route.sh "${ETCD_WATCH_VALUE}"'

  sleep 1
  echo "etcd watch was stopped, restarting.."

done
