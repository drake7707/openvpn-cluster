#!/bin/bash

set -x

echo "cur: $$"
cat <<'TEST' | /bin/bash &

echo "curinner: $$"

sleep 5
echo "Running script in daemon"

TEST

