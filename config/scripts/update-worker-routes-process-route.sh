# Helper script to process a single worker route
# requires $line = worker line
# and $masters_subnets_by_id map

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
  fi

  route_to_master=$(ip r show to "${master_vpn_subnet}")

  if [[ -z "${route_to_master}" ]]; then
    echo "There is no route to ${master_vpn_subnet}. Can't setup the route for worker with ip ${worker_ip}" 1>&2
  fi

  # route_to_master is something like 192.168.1.0/24 via ... dev tap0
  # replace it with sed with regex
  ip_route_args=$(echo "${route_to_master}" | sed -r "s/(.*?)\svia\s(.*)/${worker_ip}\/32 via \2/")

  IFS=" "
  ip r r ${ip_route_args}
fi

