#!/bin/bash
set -x 

trap "exit" INT

# The OpenVPN client has to run in a loop so that on each disconnect the remote list is updated

while true; do

  # determine if there are any remote args stored, the list will be updated by fetching the master list periodically
  remote_args=
  mkdir -p /data
  if [[ -f /data/remote_args ]]; then
    remote_args=$(cat /data/remote_args)
  fi

  openvpn --config "/vpn/client.conf" $remote_args

  echo "OpenVPN client exited"
  sleep 1
done
