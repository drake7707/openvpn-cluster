#!/bin/bash
set -x

echo "Client is connected"

set

export client_name=${OPENVPN_WORKER_NAME}
export route_vpn_gateway=${route_vpn_gateway}

cat <<'ENDSCRIPT' > /tmp/client-up.sh

set -x

# wait a bit
sleep 5

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

ENDSCRIPT

/bin/bash /tmp/client-up.sh &
