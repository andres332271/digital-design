#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
sim_dir=$(mktemp -d)
trap 'rm -rf "$sim_dir"' EXIT HUP INT TERM

iverilog -g2012 -s tb_enable_sync -o "$sim_dir/enable_sync" enable_sync.v tb_enable_sync.v
vvp "$sim_dir/enable_sync"

iverilog -g2012 -s tb_bad_bus_sync -o "$sim_dir/bad_bus_sync" bad_bus_sync.v tb_bad_bus_sync.v
vvp "$sim_dir/bad_bus_sync"
