#!/bin/bash
set -x

echo "Client is connected"

#set

export client_name=${OPENVPN_WORKER_NAME}
export route_vpn_gateway=${route_vpn_gateway}


# Run this script in a background daemon process becaues OpenVPN is completely blocked
# during this script so no requests over the VPN can be made if it's not async

cat <<'ENDSCRIPT' | /bin/bash &

set -x

# Instead of passing environment variables, query the server

IFS=
response=$(wget -q -O - http://${route_vpn_gateway}:1500/worker_connect/${client_name})

if [[ "$?" -ne 0 ]]; then
  # Connection to the worker endpoint failed, the worker table won't be updated and the fixed ip won't be set
  # Kill the openvpn client so the container restarts, this state is inconsistent
  echo "Unable to connect to the worker API endpoint, the worker table won't be updated. This state is inconsistent, killing openVPN client" 1>&2
  killall openvpn
  exit 1
fi

#echo $response | hexdump -C

IFS=$'\n' read -d '' -ra lines <<< "$response"

for line in "${lines[@]}"; do

  IFS='=' read -ra line_parts <<< "$line"
  key=${line_parts[0]}
  value=${line_parts[1]}

  if [[ "${key}" == "WORKER_IP" ]]; then
    worker_ip=${value}
  elif [[ "${key}" == "WORKER_SUBNET" ]]; then
    worker_subnet=${value}
  elif [[ "${key}" == "VPN_CLUSTER_SUBNET" ]]; then
    vpn_cluster_subnet=${value}
  fi

done


# assign worker ip & route to vpn gateway
ip a a ${worker_ip} dev tap0
ip r r ${worker_subnet} via ${route_vpn_gateway}

ip r r ${vpn_cluster_subnet} via ${route_vpn_gateway}
# make sure that the sent packet has source 5.0.0.1 when it's communicating to another worker
iptables -A POSTROUTING -o tap0 -d ${worker_subnet} -j SNAT --to-source ${worker_ip} -t nat


# write the vpn gateway to a file so the get master script can fetch the masters
mkdir -p /data
echo "${route_vpn_gateway}" > /data/vpn_gateway

# update the master list 
/config/get-masters.sh

ENDSCRIPT



