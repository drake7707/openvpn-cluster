#!/bin/bash

#ETCDCTL_API=3 etcdctl get --keys-only --prefix $1


args=
if [[ "$1" == "--skip-consensus" ]]; then
  shift
  args="${args} --consistency=s"
fi

IFS=
ETCDCTL_API=3 etcdctl get $args --keys-only --prefix "$1"
