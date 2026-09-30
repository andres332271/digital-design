#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
iverilog -g2012 -s tb_enable_sync -o sim enable_sync.v tb_enable_sync.v
vvp sim
