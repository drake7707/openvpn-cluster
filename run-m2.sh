container_name=m2-openvpn-server
vpn_subnet=192.168.2.0
vpn_subnet_mask=255.255.255.0
vpn_gateway=192.168.2.1
api_server_container_ip=localhost
VPN_PUBLIC_PORT=1195
SERVER_DATA_DIR=`pwd`/m2
VPN_WORKER_FIXED_BASE_IP=5.0.0.0

#docker run -it --entrypoint=/bin/sh \
docker run -it -d \
  --name "${container_name}" \
  --hostname "${container_name}" \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun \
  --restart=unless-stopped \
  --net=m2network \
  --ip 172.30.2.2 \
  -l vpn-cluster \
  -e VPN_KEYSIZE=${VPN_KEYSIZE:-512} \
  -e VPN_SUBNET=${vpn_subnet} \
  -e VPN_SUBNETMASK=${vpn_subnet_mask} \
  -e VPN_PORTSHARE_TARGET=${api_server_container_ip} \
  -e VPN_PORTSHARE_TARGETPORT=8000 \
  -e VPN_SERVER=${VPN_PUBLIC_IP} \
  -e VPN_SERVER_PORT=${VPN_PUBLIC_PORT} \
  -e VPN_WORKER_FIXED_BASE_IP=${VPN_WORKER_FIXED_BASE_IP} \
  -v `pwd`/config:/config \
  -v ${SERVER_DATA_DIR}/vpn:/data \
  -p ${VPN_PUBLIC_PORT}:1194 \
  idlabfuse/openvpn-clustered-server-amd64

