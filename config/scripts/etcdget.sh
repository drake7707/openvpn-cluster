#!/bin/bash

#ETCDCTL_API=3 etcdctl get --print-value-only --prefix $1

# For now don't require consensus of all other nodes to fetch a value
# because this causes issues when a new member is addded and the etcd loses quorum (for example when m2-etcd is added)
# As soon as m2-etcd is added and is not connected yet to the cluster m1-etcd will go down until m2-etcd is up
# so if m2-etcd never joins the entire cluster goes down

# TODO: this should probably be an option

set -x
args=
if [[ "$1" == "--skip-consensus" ]]; then
  shift
  args="${args} --consistency=s"
fi

ETCDCTL_API=3 etcdctl get $args --print-value-only --prefix "$1"
