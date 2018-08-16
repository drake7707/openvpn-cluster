#!/bin/sh
set -x

# if there is a rules.sh script then execute it
# this is useful to set up the correct iptables, especially as those are lost once the container restarts
if [[ -f "/rules.sh" ]]; then
  /bin/sh /rules.sh
fi

# ----------------

# Start OpenVPN client
#---------------------
/service/run-openvpn.sh &
pid1=$!
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start OpenVPN Client: $status"
  exit $status
fi

# Start periodic master fetch
#--------------------------
/service/run-periodic-fetch-masters.sh &
pid2=$!
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start periodic master fetch: $status"
  exit $status
fi


while sleep 10; do

# todo figure out why this is always exiting

#  exists1=$(jobs -p | grep -q -e "^${pid1}$"; echo $?)
#  if [[ "${exists5}" -ne 0 ]]; then
#    echo "OpenVPN client script exited." 1>&2
#    exit 1
#  fi

#  exists2=$(jobs -p | grep -q -e "^${pid2}$"; echo $?)
#  if [[ "${exists2}" -ne 0 ]]; then
#    echo "Periodic master fetch exited." 1>&2
#    exit 1
#  fi

  true
done



