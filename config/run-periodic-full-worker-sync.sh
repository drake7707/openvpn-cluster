#!/bin/bash
if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

trap "exit" INT

while true; do

  echo "Doing full update of worker routes"
  cd /config/scripts
  ./update-worker-routes.sh

  sleep 60
done
