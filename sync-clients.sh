#!/bin/bash

rsync -cavqr m1/vpn/pki/ m2/vpn/pki/ || true
rsync -cavqr m2/vpn/pki/ m3/vpn/pki/ || true
rsync -cavqr m3/vpn/pki/ m1/vpn/pki/ || true
rsync -cavqr m3/vpn/pki/ m2/vpn/pki/ || true

rsync -cavqr m1/vpn/ccd/ m2/vpn/ccd/ || true
rsync -cavqr m2/vpn/ccd/ m3/vpn/ccd/ || true
rsync -cavqr m3/vpn/ccd/ m1/vpn/ccd/ || true
rsync -cavqr m3/vpn/ccd/ m2/vpn/ccd/ || true

# todo all clients configs too BUT those need to be patched on remote
