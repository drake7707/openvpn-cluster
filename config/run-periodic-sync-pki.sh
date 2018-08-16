#!/bin/bash
set -x

trap "exit" INT

while true; do

  echo "Syncing pki from and to etcd"
  cd /config/scripts
  ./sync-pki.sh

  sleep 60
done
