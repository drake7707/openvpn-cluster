#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
set -x

own_master_ip=$(./get-vpn-ip.sh)

IFS=
workers=$(./etcdget.sh "/vpn/workers/")
masters=$(./etcdget.sh "/vpn/masters/")

# master_number;public_ip;public_port;vpn_subnet;vpn_gateway;last_updated
# e.g
#  1 ; 10.10.127.41 ; 1194 ; 192.168.1.0/24 ; 192.168.1.1 ; `date "+%Y-%m-%dT%H:%M:%S"`

declare -A masters_subnets_by_id

own_master_id=
IFS=$'\n' read -d '' -r -a master_lines <<< "${masters}" || true
for line in "${master_lines[@]}"; do
   echo "$line"
   IFS=";" read -ra line_parts <<< "${line}"

   master_nr="${line_parts[0]}"
   vpn_subnet="${line_parts[3]}"
   vpn_gateway="${line_parts[4]}"

   if [[ "${vpn_gateway}" == "${own_master_ip}" ]]; then
     own_master_id=${master_nr}
   fi

   masters_subnets_by_id[${master_nr}]="${vpn_subnet}"
done


# worker_number;worker_name;connected-to-master;worker-ip;last-updated
IFS=$'\n' read -d '' -r -a worker_lines <<< "${workers}" || true

echo "lines: ${#worker_lines[@]}"

for line in "${worker_lines[@]}"; do

   echo "Processing $line"

   IFS=";" read -ra line_parts <<< "${line}"
   on_master=${line_parts[2]}
   worker_ip=${line_parts[3]}

   if [[ "${on_master}" == "-1" ]]; then
     # not connected to any master, remove route if exists
     echo "Worker with ip ${worker_ip} isn't connected to any master, removing route"
     ip r d "${worker_ip}" || true
   elif [[ "${on_master}" == "${own_master_id}" ]]; then
     # locally connected
     echo "Worker with ip ${worker_ip} is connected locally"
     ip r r "${worker_ip}" dev tap0
   else
	# connected to a different master
 	# figure out if that master has connected to our subnet
	# or current master has a client connection to their subnet
	# actually it doesn't really matter, it must match the route to their vpn_subnet, so find that route
        master_vpn_subnet=${masters_subnets_by_id["${on_master}"]}

	if [[ -z "${master_vpn_subnet}" ]]; then
	  echo "The worker ${worker_ip} has master ${on_master} listed, but there is no entry for it in the master table. Can't setup the route for worker with ip ${worker_ip}" 1>&2
 #         exit 1
	fi

	route_to_master=$(ip r show to "${master_vpn_subnet}")

	if [[ -z "${route_to_master}" ]]; then
	  echo "There is no route to ${master_vpn_subnet}. Can't setup the route for worker with ip ${worker_ip}" 1>&2
#	  exit 1
	fi

	# route_to_master is something like 192.168.1.0/24 via ... dev tap0
	# replace it with sed with regex
	ip_route_args=$(echo "${route_to_master}" | sed -r "s/(.*?)\svia\s(.*)/${worker_ip}\/32 via \2/")

	IFS=" "
	ip r r ${ip_route_args}
   fi

done
