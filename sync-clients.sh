#!/bin/bash

rsync -cavqr m1/vpn/pki/ m2/vpn/pki/ || true
rsync -cavqr m2/vpn/pki/ m3/vpn/pki/ || true
rsync -cavqr m3/vpn/pki/ m1/vpn/pki/ || true
rsync -cavqr m3/vpn/pki/ m2/vpn/pki/ || true

# todo all clients configs too BUT those need to be patched on remote
