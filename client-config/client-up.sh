#!/bin/bash

echo "Client is connected"

#set

# The server will push the vpn cluster info through environment variables.
# The fixed ip for the worker is in OPENVPN_WORKER_IP


# TODO: calculate and update the variables below

# assign 5.0.0.3 to w3 & route to vpn gateway
ip a a ${OPENVPN_WORKER_IP} dev tap0
ip r r ${OPENVPN_VPN_WORKER_SUBNET} via ${route_vpn_gateway}

ip r r 192.168.0.0/16 via ${route_vpn_gateway}
# make sure that the sent packet has source 5.0.0.1 when it's communicating to another worker
iptables -A POSTROUTING -o tap0 -m iprange --dst-range 5.0.0.0-5.255.255.255 -j SNAT --to-source 5.0.0.3 -t nat


