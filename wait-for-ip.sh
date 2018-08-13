#!/bin/bash

vpn_name=$1
network_adapter=tap0

function get-vpn-ip {
  vpn_ip=$((docker exec "${vpn_name}" ip addr show ${network_adapter} 2>/dev/null | grep -oP "(?<=inet ).*(?=/)" | cut -d ' ' -f 1) || true)
  echo $vpn_ip
}

function wait-for-ip {
  local n=1
  local ntries=60
  while true; do

    vpn_ip=$(get-vpn-ip ${vpn_server_name})

    if [[ "$vpn_ip" ]]; then
      if ((--n == 0)); then
        echo "[done]" >&2
        break
      fi
    else
      n=3
    fi
    if ((--ntries == 0)); then
      echo "Error waiting for vpn to establish connection"
      exit 1
    fi
    echo -n "." >&2
    sleep 1
  done
}

wait-for-ip
