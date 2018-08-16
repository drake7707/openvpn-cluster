#!/bin/bash
if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

port=${1:-1500}

function worker_connect() {
  local worker_name=$1

  # update the etcd worker table
  cd /config/scripts
  /config/scripts/update-worker-table.sh connect ${worker_name} 1>/dev/null 2>&1

  # update the worker routes
  cd /config/scripts
  /config/scripts/update-worker-routes.sh 1>/dev/null 2>&1

  ip=$(cd /config/scripts && ./get-worker-fixed-ip.sh "${worker_name}")
  worker_subnet=$(cd /config/scripts && ./etcdget.sh "/vpn/config/worker_subnet")
  cluster_subnet=$(cd /config/scripts && ./etcdget.sh "/vpn/config/cluster_subnet")

  #  printf "%s\n" "WORKER_IP=5.0.0.5"
  #  printf "%s\n" "WORKER_SUBNET=5.0.0.0/8"
  #  printf "%s\n" "VPN_CLUSTER_SUBNET=192.168.0.0/16"

  printf "%s\n" "WORKER_IP=${ip}"
  printf "%s\n" "WORKER_SUBNET=${worker_subnet}"
  printf "%s\n" "VPN_CLUSTER_SUBNET=${cluster_subnet}"
}

function get_masters() {
  cd /config/scripts

  masters=$(cd /config/scripts && ./get-masters-public-ip.sh)
  printf "%s\n" "${masters}"
}

rm -f out
mkfifo out
trap "rm -f out" EXIT
while true
do
  cat out | nc -l -p ${port} > >( # parse the netcat output, to build the answer redirected to the pipe "out".
    export pid=$$

    export REQUEST=
    while read line
    do
      line=$(echo "$line" | tr -d '[\r\n]')

      if echo "$line" | grep -qE '^GET /' # if line starts with "GET /"
      then
        REQUEST=$(echo "$line" | cut -d ' ' -f2) # extract the request
      elif [ "x$line" = x ] # empty line / end of request
      then
        HTTP_200="HTTP/1.1 200 OK"
        HTTP_LOCATION="Location:"
        HTTP_404="HTTP/1.1 404 Not Found"
        # call a script here
        # Note: REQUEST is exported, so the script can parse it (to answer 200/403/404 status code + content)
        if echo $REQUEST | grep -qE '^/worker_connect'; then
          IFS='/' read -ra url_parts <<< "$REQUEST"
          len=${#url_parts[@]}
          worker_name=${url_parts[len-1]}
          
          result=$(worker_connect ${worker_name})
	        printf "%s\n\n%s\n" "$HTTP_200" "${result}" > out
	        
          0<&-
        elif echo $REQUEST | grep -qE '^/masters'; then

          result=$(get_masters)
	        printf "%s\n\n%s\n" "$HTTP_200" "${result}" > out
	        0<&-
        
        else
            printf "%s\n%s %s\n\n%s\n" "$HTTP_404" "$HTTP_LOCATION" $REQUEST "Resource $REQUEST NOT FOUND!" > out
        fi
      fi
    done
  )
done
