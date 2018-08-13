set -x

container_name=m2-etcd
vpn_subnet=192.168.2.0
vpn_subnet_mask=255.255.255.0
vpn_gateway=192.168.2.1
SERVER_DATA_DIR=`pwd`/m2

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


docker create \
  --net=m2network \
  -v ${SERVER_DATA_DIR}/etcd:/etcd-data \
  --name ${container_name} \
  --hostname ${container_name} \
  --restart on-failure \
  --ip 172.30.2.3 \
  --cap-add=NET_ADMIN \
  -l vpn-cluster \
  -e NAME="${container_name}" \
  -e LISTEN_IP="0.0.0.0" \
  -e ADVERTISE_IP="${vpn_gateway}" \
  -e INITIAL_CLUSTER="${initial_cluster}" \
  -e INITIAL_CLUSTER_STATE="existing" \
  idlabfuse/etcd-amd64:latest
