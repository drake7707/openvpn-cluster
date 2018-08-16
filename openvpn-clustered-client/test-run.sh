container_name=test-openvpnclient

docker rm -f ${container_name}

docker run -d \
  --name "${container_name}" \
  --hostname "${container_name}" \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun \
  --restart=unless-stopped \
  -v ${VPN_CONFIG_FILE}:/vpn/client.conf \
  idlabfuse/openvpn-clustered-client-amd64
