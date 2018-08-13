#!/bin/bash

# Script that will be executed once the base client config file is generated

client_name=$1
client_type=$2

function helper::ip2int()
{
    local a b c d
    { IFS=. read a b c d; } <<< $1
    echo $(((((((a << 8) | b) << 8) | c) << 8) | d))
}

function helper::int2ip()
{
    local ui32=$1; shift
    local ip n
    ip=
    for n in 1 2 3 4; do
        ip=$((ui32 & 0xff))${ip:+.}$ip
        ui32=$((ui32 >> 8))
    done
    echo $ip
}

function helper::netmask()
{
    local mask=$((0xffffffff << (32 - $1))); shift
    helper::int2ip $mask
}

function helper::network()
{
    local addr=$(helper::ip2int $1); shift
    local mask=$((0xffffffff << (32 -$1))); shift
    helper::int2ip $((addr & mask))
}


function helper::add_to_ip {
    val=$(helper::ip2int $1)
    ((val+=$2))
    helper::int2ip val
}


# determine the fixed ip to assign to the client
nr_of_clients=$(ls -1 /data/ccd/ | wc -l)
new_nr=${nr_of_clients}
((new_nr++))
((new_nr++))


# Build the ccd specific rules
client_ip=$(helper::add_to_ip ${VPN_SUBNET} ${new_nr})
# Push the fixed ip in the vpn subnet, only valid for the current vpn server!
echo "ifconfig-push ${client_ip} ${VPN_SUBNETMASK}" > /data/ccd/${client_name}
