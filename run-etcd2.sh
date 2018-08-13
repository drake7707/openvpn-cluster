container_name=m2-etcd
vpn_subnet=192.168.2.0
vpn_subnet_mask=255.255.255.0
vpn_gateway=192.168.2.1
SERVER_DATA_DIR=`pwd`/m2
VPN_PUBLIC_IP=10.10.127.41

NODE_IP2=172.30.2.3

# register the member in the cluster, this will have to be done on the join server side

joinresult=$(docker exec m1-etcd etcdctl --endpoint http://m1-etcd:2379 member add ${container_name} http://${vpn_gateway}:2380)
echo $joinresult

initial_cluster=$(echo $joinresult | grep -oE "ETCD_INITIAL_CLUSTER=\"(.*?)\"\s")
initial_cluster="${initial_cluster:21}"
initial_cluster=$"${initial_cluster%[[:space:]]}" # trim trailing space
initial_cluster="${initial_cluster%\"}" # trim suffix quote
initial_cluster="${initial_cluster#\"}" # trim prefix quote
#echo ${initial_cluster}

  docker run \
    -d \
    --net=m2network \
    --volume=${SERVER_DATA_DIR}/etcd:/etcd-data \
    --name ${container_name} \
    --hostname ${container_name} \
    --ip ${NODE_IP2} \
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
    --initial-cluster="${initial_cluster}" \
    --initial-cluster-state=existing

