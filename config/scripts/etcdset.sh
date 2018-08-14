#!/bin/bash

ETCDCTL_API=3 etcdctl put "$1" "$2"
