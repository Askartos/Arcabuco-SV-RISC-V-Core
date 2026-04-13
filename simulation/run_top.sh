#!/bin/bash

./clean.sh

TRACE_FLAG=""
GUI=false

for arg in "$@"; do
  if [[ "$arg" == "-gui" ]]; then
    TRACE_FLAG="--trace"
    GUI=true
  fi
done

verilator --binary \
  -f file_list.txt \
  --top arcabuco_system_tb \
  -Wno-TIMESCALEMOD -Wno-fatal \
  $TRACE_FLAG

./obj_dir/Varcabuco_system_tb

if $GUI; then
  gtkwave arcabuco_sim.vcd
fi