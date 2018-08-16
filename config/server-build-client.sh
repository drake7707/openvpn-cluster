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

prefix=
if [[ ! -z ${client_type} ]]; then
  prefix="${client_type}-"
fi

clientConfig=/data/clients/${prefix}${client_name}.conf

# if it's a worker then also set the client up script to execute to 
# complete the worker ip and ruleset
if [[ ${client_type} == "worker" ]]; then
   echo "script-security 2" >> ${clientConfig}
   echo "up /config/client-up.sh" >> ${clientConfig}
fi


# determine the fixed ip to assign to the client
nr_of_clients=$(ls -1 /data/ccd/ | wc -l)
new_nr=${nr_of_clients}
new_nr=$((new_nr+1))
new_nr=$((new_nr+1)) # start from 2


# Build the ccd specific rules
client_ip=$(helper::add_to_ip ${VPN_SUBNET} ${new_nr})
# Push the fixed ip in the vpn subnet, only valid for the current vpn server!
echo "ifconfig-push ${client_ip} ${VPN_SUBNETMASK}" > /data/ccd/${client_name}


# The pki and cert for the client is already generated, push those files to etcd if it's a worker or a master
if [[ ${client_type} == "worker" ]]; then

#  /config/scripts/etcdset.sh "/vpn/pki/private/${prefix}${client_name}.key" "$(cat /data/pki/private/${prefix}${client_name}.key)"
#  /config/scripts/etcdset.sh "/vpn/pki/issued/${prefix}${client_name}.crt" "$(cat /data/pki/private/${prefix}${client_name}.crt)"

  # Force a sync of the new pki of the client. If etcd is unreachable it's fine, it will periodically sync and will eventually get on there
  (cd /config/scripts && ./sync-pki.sh || true) &
fi

