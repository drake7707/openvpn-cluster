
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


