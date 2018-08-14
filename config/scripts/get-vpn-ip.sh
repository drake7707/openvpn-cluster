#!/bin/bash

#(ip addr show tap0 2>/dev/null | grep -oP "(?<=inet ).*(?=/)" | cut -d ' ' -f 1) || true
(ip addr show tap0 2>/dev/null | grep -e "inet " | cut -d ' ' -f 6 | cut -d '/' -f 1) || true
