container_name=m3-openvpn-server
vpn_subnet=192.168.3.0
vpn_subnet_mask=255.255.255.0
api_server_container_ip=localhost
VPN_PUBLIC_PORT=1196
SERVER_DATA_DIR=`pwd`/m3
VPN_PUBLIC_IP=192.168.0.120


docker run -d \
  --name "${container_name}" \
  --hostname "${container_name}" \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun \
  --restart=unless-stopped \
  --net=m3network \
  -l vpn-cluster \
  -e VPN_KEYSIZE=${VPN_KEYSIZE:-512} \
  -e VPN_SUBNET=${vpn_subnet} \
  -e VPN_SUBNETMASK=${vpn_subnet_mask} \
  -e VPN_PORTSHARE_TARGET=${api_server_container_ip} \
  -e VPN_PORTSHARE_TARGETPORT=8000 \
  -e VPN_SERVER=${VPN_PUBLIC_IP} \
  -e VPN_SERVER_PORT=${VPN_PUBLIC_PORT} \
  -v `pwd`/config:/config \
  -v ${SERVER_DATA_DIR}/vpn:/data \
  -p ${VPN_PUBLIC_PORT}:1194 \
  idlabfuse/openvpn-server-amd64
