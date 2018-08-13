#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
set -x 

#### Clean everything
./clean.sh

#### Create separate networks
docker network create -d bridge --subnet 172.30.1.0/24 m1network
docker network create -d bridge --subnet 172.30.2.0/24 m2network
docker network create -d bridge --subnet 172.30.3.0/24 m3network
docker network create -d bridge --subnet 172.40.1.0/24 w1network
docker network create -d bridge --subnet 172.40.2.0/24 w2network
docker network create -d bridge --subnet 172.40.3.0/24 w3network

m1_vpn_gateway=192.168.1.1
m2_vpn_gateway=192.168.2.1
m3_vpn_gateway=192.168.3.1

m1_etcd_ip=172.30.1.3
m1_openvpn_ip=172.30.1.2

m2_etcd_ip=172.30.2.3
m2_openvpn_eth_ip=172.30.2.2

m2m1_eth_ip=172.30.2.4



#### Start M1 OpenVPN Server
./run-m1.sh
./wait-for-ip.sh m1-openvpn-server

#### Setup NAT rules on m1 so 2379 and 2380 on vpn server get port forwarded to the etcd container

docker exec -i m1-openvpn-server /bin/sh <<EOF

# forward everything that comes from the vpn net back to the eth0 and vice versa
iptables -A FORWARD -p tcp --match multiport --sports 2379,2380 -i eth0 -o tap0 -j ACCEPT
iptables -A FORWARD -p tcp --match multiport --dports 2379,2380 -i tap0 -o eth0 -j ACCEPT
# rewrite the destination for all packets that are received on ports 2379 and 2380 and have destination the master
iptables -A PREROUTING -t nat -p tcp -d ${m1_vpn_gateway} --match multiport --dports 2379,2380 -j DNAT --to-destination ${m1_etcd_ip}
# rewrite the source for all replying packets going to eth0 or the destination will not know where to send the reply to
#iptables -A POSTROUTING -t nat -o eth0 -p tcp --match multiport --dports 2379,2380 -j SNAT --to-source ${m1_vpn_gateway}

# nat hairpin for etcd
iptables -A POSTROUTING -o eth0 -s ${m1_etcd_ip} -d ${m1_etcd_ip} -j SNAT --to-source ${m1_vpn_gateway} -t nat

# all packets that go into the vpn range must have the vpn gateway as source, because the network knows the gateways but not the eth0 local addresses
iptables -A POSTROUTING -o eth0 -m iprange --dst-range 192.168.0.0-192.168.255.255 -j SNAT --to-source ${m1_vpn_gateway} -t nat
EOF


#### Create M1 Etcd, but not started yet
./create-etcd1.sh

# write the networking rules
tmp_etcd1rules=$(mktemp /tmp/etcd1-rules.sh.XXXXXX)
cat <<EOFRULES >> ${tmp_etcd1rules}
# Add route so m1-etcd can resolve the advertisement ips
ip r r 192.168.0.0/16 via ${m1_openvpn_ip}
EOFRULES
chmod u+x ${tmp_etcd1rules}
docker cp ${tmp_etcd1rules} m1-etcd:/rules.sh
rm ${tmp_etcd1rules}

# now start it
docker start m1-etcd


#### Setup cert to M2 server
mkdir -p m2/vpn && cp -r m1/vpn/* m2/vpn
rm -f m2/vpn/server.conf

#### Start M2 OpenVPN Server
./run-m2.sh
./wait-for-ip.sh m2-openvpn-server

#### Setup NAT rules on m2 so 2379 and 2380 on vpn server get port forwarded to the etcd container

docker exec -i m2-openvpn-server /bin/sh <<EOF

# forward everything that comes from the vpn net back to the eth0 and vice versa
iptables -A FORWARD -p tcp --match multiport --sports 2379,2380 -i eth0 -o tap0 -j ACCEPT
iptables -A FORWARD -p tcp --match multiport --dports 2379,2380 -i tap0 -o eth0 -j ACCEPT

# rewrite the destination for all packets that are received on ports 2379 and 2380 and have destination the master
iptables -A PREROUTING -t nat -p tcp -d ${m2_vpn_gateway} --match multiport --dports 2379,2380 -j DNAT --to-destination ${m2_etcd_ip}
# rewrite the source for all replying packets going to eth0 or the destination will not know where to send the reply to
#iptables -A POSTROUTING -t nat -o eth0 -p tcp --match multiport --dports 2379,2380 -j SNAT --to-source ${m2_openvpn_eth_ip}

# nat hairpin for etcd
iptables -A POSTROUTING -o eth0 -s ${m2_etcd_ip} -d ${m2_etcd_ip} -j SNAT --to-source ${m1_vpn_gateway} -t nat

# all packets that go into the vpn range must have the vpn gateway as source, because the network knows the gateways but not the eth0 local addresses
iptables -A POSTROUTING -o eth0 -m iprange --dst-range 192.168.0.0-192.168.255.255 -j SNAT --to-source ${m2_vpn_gateway} -t nat
EOF


#### Create M2 etcd
./create-etcd2.sh

# write the networking rules
tmp_etcd2rules=$(mktemp /tmp/etcd2-rules.sh.XXXXXX)
cat <<EOFRULES >> ${tmp_etcd2rules}
# Add route so m2-etcd can resolve the advertisement ips
ip r r 192.168.0.0/16 via ${m2_openvpn_eth_ip}
EOFRULES
chmod u+x ${tmp_etcd2rules}
docker cp ${tmp_etcd2rules} m2-etcd:/rules.sh
rm ${tmp_etcd2rules}

##### TODO:
######## ETCD can't be started now because the routing for 192.168.1.1 <-> 192.168.2.1 is not yet complete in the routing table of the masters!
#########################

# now start m2-etcd
docker start m2-etcd


# M2 joins the M1 network as master
docker exec m1-openvpn-server /service/build_client m2 master
./run-client.sh m2m1 `pwd`/m1/vpn/clients/m2.conf m2network ${m2m1_eth_ip}
./sync-clients.sh
sleep 1



##"## Setup cert to M3 server
#mkdir -p m3/vpn && cp -r m1/vpn/* m3/vpn
#rm -f m3/vpn/server.conf

# Start M3 OpenVPN Server
#./run-m3.sh
#sleep 3

# M3 joins the M1 network as master
#docker exec m1-openvpn-server /service/build_client m3m1 master
#./run-client.sh m3m1 `pwd`/m1/vpn/clients/m3m1.conf m3network
#./sync-clients.sh
#sleep 1

# M3 joins the M2 network as master
#docker exec m2-openvpn-server /service/build_client m3m2 master
#./run-client.sh m3m2 `pwd`/m2/vpn/clients/m3m2.conf m3network
#./sync-clients.sh
#sleep 1

# W1 joins M1: Create vpn profile for w1 on M1
docker exec m1-openvpn-server /service/build_client w1 worker
./run-client.sh w1 `pwd`/m1/vpn/clients/w1.conf w1network
./sync-clients.sh
sleep 1

# W2 joins M2
docker exec m2-openvpn-server /service/build_client w2 worker
./run-client.sh w2 `pwd`/m2/vpn/clients/w2.conf w2network
./sync-clients.sh

# W3 joins M1
docker exec m1-openvpn-server /service/build_client w3 worker
./run-client.sh w3 `pwd`/m1/vpn/clients/w3.conf w3network
./sync-clients.sh

sleep 5

#### When workers join the cluster they need to get a fixed number
#### the 5.0.0.0/8 route could be added in the ccd so the vpn gateway is easier

# assign 5.0.0.1 to w1 & route to vpn gateway
docker exec -it w1-openvpn-client ip a a 5.0.0.1 dev tap0
docker exec -it w1-openvpn-client ip r r 5.0.0.0/8 via ${m1_vpn_gateway}
docker exec -it w1-openvpn-client ip r r 192.168.0.0/16 via ${m1_vpn_gateway}
# make sure that the sent packet has source 5.0.0.1 when it's communicating to another worker
docker exec -it w1-openvpn-client iptables -A POSTROUTING -o tap0 -m iprange --dst-range 5.0.0.0-5.255.255.255 -j SNAT --to-source 5.0.0.1 -t nat

# assign 5.0.0.2 to w2 & route to vpn gateway
docker exec -it w2-openvpn-client ip a a 5.0.0.2 dev tap0
docker exec -it w2-openvpn-client ip r r 5.0.0.0/8 via ${m2_vpn_gateway}
docker exec -it w2-openvpn-client ip r r 192.168.0.0/16 via ${m2_vpn_gateway}
# make sure that the sent packet has source 5.0.0.1 when it's communicating to another worker
docker exec -it w2-openvpn-client iptables -A POSTROUTING -o tap0 -m iprange --dst-range 5.0.0.0-5.255.255.255 -j SNAT --to-source 5.0.0.2 -t nat

# assign 5.0.0.3 to w3 & route to vpn gateway
docker exec -it w3-openvpn-client ip a a 5.0.0.3 dev tap0
docker exec -it w3-openvpn-client ip r r 5.0.0.0/8 via ${m1_vpn_gateway}
docker exec -it w3-openvpn-client ip r r 192.168.0.0/16 via ${m1_vpn_gateway}
# make sure that the sent packet has source 5.0.0.1 when it's communicating to another worker
docker exec -it w3-openvpn-client iptables -A POSTROUTING -o tap0 -m iprange --dst-range 5.0.0.0-5.255.255.255 -j SNAT --to-source 5.0.0.3 -t nat


# routing table for m1
docker exec -it m1-openvpn-server ip r r 5.0.0.1 dev tap0 # w1 is connected locally
m2m1_in_m1_ip=192.168.1.2
docker exec -it m1-openvpn-server ip r r 5.0.0.2 via ${m2m1_in_m1_ip} dev tap0 # w2 is connected on m2
docker exec -it m1-openvpn-server ip r r 5.0.0.3 dev tap0 # w3 is connected locally
# rules on m1 so 192.168/16 traffic works. this will be necessary for etcd
docker exec -it m1-openvpn-server ip r r 192.168.2.0/24 via ${m2m1_in_m1_ip} dev tap0
# need to masquerade otherwise anything on the m1network will send its own eth0 ip as source ip in the packet and the receiver doesn't know what to do with it
docker exec -it m1-openvpn-server iptables -A POSTROUTING -t nat -m iprange --dst-range 192.168.0.0-192.168.255.255 -o tap0 -j MASQUERADE


# routing table for m2m1
docker exec -i m2m1-openvpn-client /bin/sh <<EOF

# Create the 2 tables to add specific routes on
echo "2     toeth" >> /etc/iproute2/rt_tables
echo "3     totap" >> /etc/iproute2/rt_tables

# Everything coming from eth0 will be going to the totap table and everything from tap0 will be going to the toeth table
ip rule add table totap iif eth0
ip rule add table toeth iif tap0

# Add the routes but on the specific table
ip r r 0.0.0.0/0 via ${m1_vpn_gateway} table totap
ip r r 0.0.0.0/0 via ${m2_openvpn_eth_ip} table toeth

EOF



# routing table for m2
# m2 has m2m1 as client to m1 so the routes are slightly differt
docker exec -it m2-openvpn-server ip r r 5.0.0.1 via ${m2m1_eth_ip} dev eth0 # w1
docker exec -it m2-openvpn-server ip r r 5.0.0.2 dev tap0 # w2 is connected locally
docker exec -it m2-openvpn-server ip r r 5.0.0.3 via ${m2m1_eth_ip} dev eth0 # w3
# rules on m2 so 192.168/16 traffic
docker exec -it m2-openvpn-server iptables -A POSTROUTING -t nat -m iprange --dst-range 192.168.0.0-192.168.255.255 -o tap0 -j MASQUERADE
docker exec -it m2-openvpn-server ip r r 192.168.1.0/24 via ${m2m1_eth_ip} dev eth0


# TODO: m3 isn't set up

echo "Current status of network:"

echo "################### M1 ###############"
docker exec m1-openvpn-server ip a
docker exec m1-openvpn-server ip r

echo "################### M2 ###############"
docker exec m2-openvpn-server ip a
docker exec m2-openvpn-server ip r

echo "################### M3 ###############"
docker exec m3-openvpn-server ip a
docker exec m3-openvpn-server ip r

echo "################### W1 ###############"
docker exec w1-openvpn-client ip a
docker exec w1-openvpn-client ip r

echo "################### W2 ###############"
docker exec w2-openvpn-client ip a
docker exec w2-openvpn-client ip r

echo "################### W3 ###############"
docker exec w3-openvpn-client ip a
docker exec w3-openvpn-client ip r


echo "################### M2M1 ###############"
docker exec m2m1-openvpn-client ip a
docker exec m2m1-openvpn-client ip r

echo "################### M3M1 ###############"
docker exec m3m1-openvpn-client ip a
docker exec m3m1-openvpn-client ip r

echo "################### M3M2 ###############"
docker exec m3m2-openvpn-client ip a
docker exec m3m2-openvpn-client ip r










