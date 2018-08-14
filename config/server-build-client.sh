#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
set -x


# Script that will be executed once the base client config file is generated

client_name=$1
client_type=$2

source /config/scripts/helper.sh


# determine the fixed ip to assign to the client
nr_of_clients=$(ls -1 /data/ccd/ | wc -l)
new_nr=${nr_of_clients}
new_nr=$((new_nr+1))
new_nr=$((new_nr+1)) # start from 2


# Build the ccd specific rules
client_ip=$(helper::add_to_ip ${VPN_SUBNET} ${new_nr})
# Push the fixed ip in the vpn subnet, only valid for the current vpn server!
echo "ifconfig-push ${client_ip} ${VPN_SUBNETMASK}" > /data/ccd/${client_name}
