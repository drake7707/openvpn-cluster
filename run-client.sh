container_name=$1-openvpn-client
VPN_CONFIG_FILE=$2
network=$3

docker rm -f ${container_name}

docker run -d \
  --name "${container_name}" \
  --hostname "${container_name}" \
  --net=${network} \
  -l vpn-cluster \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun \
  --restart=unless-stopped \
  -v ${VPN_CONFIG_FILE}:/vpn/client.conf \
  idlabfuse/openvpn-client-amd64
