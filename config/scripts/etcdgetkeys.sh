#!/bin/bash

#ETCDCTL_API=3 etcdctl get --keys-only --prefix $1

ETCDCTL_API=3 etcdctl get --consistency="s" --keys-only --prefix $1
