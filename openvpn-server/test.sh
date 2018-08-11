#!/bin/sh



ip2int()
{
    local a b c d
    { IFS=. read a b c d; } <<< $1
    echo $(((((((a << 8) | b) << 8) | c) << 8) | d))
}

int2ip()
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


netmask()
{
    local mask=$((0xffffffff << (32 - $1))); shift
    int2ip $mask
}

network()
{
    local addr=$(helper::ip2int $1); shift
    local mask=$((0xffffffff << (32 -$1))); shift
    int2ip $((addr & mask))
}

val=$(ip2int "5.0.0.0")
((val++))

int2ip val
