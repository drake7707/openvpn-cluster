set -x

container_name=m1-etcd
vpn_subnet=192.168.1.0
vpn_subnet_mask=255.255.255.0
vpn_gateway=192.168.1.1
SERVER_DATA_DIR=`pwd`/m1

# M1 is the initial cluster

docker create \
  --net=m1network \
  -v ${SERVER_DATA_DIR}/etcd:/etcd-data \
  --name ${container_name} \
  --hostname ${container_name} \
  --ip 172.30.1.3 \
  --cap-add=NET_ADMIN \
  -l vpn-cluster \
  -e NAME="${container_name}" \
  -e LISTEN_IP="0.0.0.0" \
  -e ADVERTISE_IP="${vpn_gateway}" \
  -e INITIAL_CLUSTER="${container_name}=http://${vpn_gateway}:2380" \
  -e INITIAL_CLUSTER_STATE="new" \
  idlabfuse/etcd-amd64:latest








