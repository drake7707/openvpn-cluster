container_name=m1-etcd
vpn_subnet=192.168.1.0
vpn_subnet_mask=255.255.255.0
vpn_gateway=192.168.1.1
SERVER_DATA_DIR=`pwd`/m1

# M1 is the initial cluster

docker run \
  -d \
  --net=m1network \
  -v ${SERVER_DATA_DIR}/etcd:/etcd-data \
  --name ${container_name} \
  --hostname ${container_name} \
  --ip 172.30.1.3 \
  --cap-add=NET_ADMIN \
  -l vpn-cluster \
  quay.io/coreos/etcd:latest \
  /usr/local/bin/etcd \
  --data-dir=/etcd-data \
  --name ${container_name} \
  --initial-advertise-peer-urls http://${vpn_gateway}:2380 \
  --listen-peer-urls http://0.0.0.0:2380 \
  --advertise-client-urls http://${vpn_gateway}:2379 \
  --listen-client-urls http://0.0.0.0:2379 \
  --initial-cluster ${container_name}=http://${vpn_gateway}:2380








