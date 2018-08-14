
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


