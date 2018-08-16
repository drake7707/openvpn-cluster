#!/bin/bash
set -x

keys=$(./etcdgetkeys.sh "/vpn/pki/")

declare -A keyMap

# worker_number;worker_name;connected-to-master;worker-ip;last-updated
IFS=$'\n' read -d '' -r -a key_lines <<< "${keys}" || true

#ensure the folders exist
mkdir -p /data/pki/issued
mkdir -p /data/pki/private
mkdir -p /data/pki/certs_by_serial

for line in "${key_lines[@]}"; do

 # e.g. /vpn/pki/private/worker-w1.key
 local_file=$(echo $line |  sed -e "s/^\/vpn/\/data/")

 if [[ ! -f "${local_file}" ]]; then
    # file does not exist locally, pull it
    ./etcdget.sh "$line" > "${local_file}"
 fi

 keyMap["$line"]=1
done

existing_files=$(find "/data/pki/" | grep -e ".key$\|.crt$\|.pem$")

IFS=$'\n' read -d '' -r -a existing_file_lines <<< "${existing_files}" || true

for file in "${existing_file_lines[@]}"; do

  remote_filename=$(echo $file | sed -e "s/^\/data/\/vpn/")
  if [[ "${keyMap[${remote_filename}]}" != 1 ]]; then
    # file does not exist in etcd, push it
    ./etcdset.sh "${remote_filename}" "$(cat ${file})"
  fi

done

