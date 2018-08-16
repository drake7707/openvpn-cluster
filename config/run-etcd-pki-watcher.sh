#!/bin/bash
if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

trap "exit" INT

while true; do

  # when anything of pki updates in etcd, force a sync of the pki data
  cd /config/scripts
  ./etcdwatch.sh "/vpn/pki" './sync-pki.sh'

  sleep 1
  echo "etcd watch on /vpn/pki was stopped, restarting.."

done
