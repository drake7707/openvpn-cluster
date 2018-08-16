#!/bin/sh
set -x

# Setup rules to forward traffic from the docker eth0 bridge to the vpn tunnel and back
VPN_CONFIG=/vpn/client.conf

# if there is a rules.sh script then execute it
# this is useful to set up the correct iptables, especially as those are lost once the container restarts
if [[ -f "/rules.sh" ]]; then
  /bin/sh /rules.sh
fi

# Start openvpn in the background

# determine if there are any remote args stored, the list will be updated by fetching the master list periodically
remote_args=
mkdir -p /data
if [[ -f /data/remote_args ]]; then
  remote_args=$(cat /data/remote_args)
fi

openvpn --config "${VPN_CONFIG}" $remote_args
