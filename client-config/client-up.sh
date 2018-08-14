#!/bin/bash
set -x

echo "Client is connected"

#set

client_name=${X509_0_CN}

# Instead of passing environment variables, query the server 

IFS=
response=$(wget -q -O - http://${route_vpn_gateway}:1500/worker_connect/${client_name})

echo $response | hexdump -C

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


