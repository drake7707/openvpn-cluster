#!/bin/bash

trap "exit" INT

# only fetch it after a while so it doesn't interfere with the connect
sleep 60

while true; do
 
  /config/get-masters.sh
  sleep 60

done


