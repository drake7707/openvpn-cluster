#!/bin/bash

rsync -cavqr m1/vpn/pki/ m2/vpn/pki/
rsync -cavqr m2/vpn/pki/ m3/vpn/pki/
rsync -cavqr m3/vpn/pki/ m1/vpn/pki/
rsync -cavqr m3/vpn/pki/ m2/vpn/pki/

rsync -cavqr m1/vpn/ccd/ m2/vpn/ccd/
rsync -cavqr m2/vpn/ccd/ m3/vpn/ccd/
rsync -cavqr m3/vpn/ccd/ m1/vpn/ccd/
rsync -cavqr m3/vpn/ccd/ m2/vpn/ccd/

# todo all clients configs too BUT those need to be patched on remote
