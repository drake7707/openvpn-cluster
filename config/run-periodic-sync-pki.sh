#!/bin/bash
if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

trap "exit" INT

while true; do

  echo "Syncing pki from and to etcd"
  cd /config/scripts
  ./sync-pki.sh

  sleep 60
done
