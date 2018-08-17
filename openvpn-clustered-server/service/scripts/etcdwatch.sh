#!/bin/bash

# Note etcdctl watch will stop if the etcd cluster becomes unhealthy

ETCDCTL_API=3 etcdctl watch --prefix "$1" -- sh -c "$2"
