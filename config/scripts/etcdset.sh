#!/bin/bash

IFS=
export ETCDCTL_API=3
echo "$2" | etcdctl put "$1"
