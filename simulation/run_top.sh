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
  --top arcabuco_datapath_tb \
  -Wno-TIMESCALEMOD -Wno-WIDTHEXPAND -Wno-fatal -Wno-SYMRSVDWORD\
  $TRACE_FLAG
  
./obj_dir/Varcabuco_datapath_tb

if $GUI; then
  gtkwave arcabuco_sim.vcd
fi
