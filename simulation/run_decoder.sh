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
../src/rtl/arcabuco_core/riscv_decoder.sv \
../src/tb/decoder_tb.sv \
--top riscv_decoder_tb -Wno-TIMESCALEMOD \
  $TRACE_FLAG


#run simulation
./obj_dir/Vriscv_decoder_tb 

if $GUI; then
  gtkwave decoder.vcd
fi
