#!/bin/bash

set -x

container_name=$1-openvpn-client
VPN_CONFIG_FILE=$2
network=$3
ip=${4:-}

ipaddr=
if [[ ! -z ${ip} ]]; then
  ipaddr="--ip ${ip}"
else
  ipaddr=""
fi

docker rm -f ${container_name}


docker run -d \
  --name "${container_name}" \
  --hostname "${container_name}" \
  --net=${network} \
  -l vpn-cluster \
  ${ipaddr} \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun \
  --restart=unless-stopped \
  -v ${VPN_CONFIG_FILE}:/vpn/client.conf \
  idlabfuse/openvpn-client-amd64
