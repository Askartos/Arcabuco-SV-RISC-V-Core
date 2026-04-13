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

#list all
verilator --binary \
../src/rtl/arcabuco_core/arcabuco_core_pack.sv \
../src/rtl/arcabuco_core/arcabuco_decoder.sv \
../src/rtl/arcabuco_core/regfile.sv \
../src/rtl/arcabuco_core/arcabuco_regs_deco.sv \
../src/tb/regs_decoder_tb.sv \
--top arcabuco_decoder_tb -Wno-TIMESCALEMOD \
  $TRACE_FLAG

#run simulation
./obj_dir/Varcabuco_decoder_tb 

if $GUI; then
  gtkwave decoder.vcd
fi

