#!/bin/bash

./clean.sh 

#list all
verilator --binary \
../src/rtl/arcabuco_core/arcabuco_core_pack.sv \
../src/rtl/arcabuco_core/arcabuco_decoder.sv \
../src/rtl/arcabuco_core/regfile.sv \
../src/rtl/arcabuco_core/arcabuco_regs_deco.sv \
../src/tb/regs_decoder_tb.sv \
--top arcabuco_decoder_tb -Wno-TIMESCALEMOD\

#run simulation
./decoder.sim
#if any argument open  gui
if [ ! -z $1 ]; then
  gtkwave decoder.vcd
fi

