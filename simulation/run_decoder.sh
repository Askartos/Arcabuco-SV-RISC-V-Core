#!/bin/bash

./clean.sh 

#list all
verilator --binary \
../src/rtl/arcabuco_core/arcabuco_core_pack.sv \
../src/rtl/arcabuco_core/arcabuco_decoder.sv \
../src/tb/decoder_tb.sv \
--top arcabuco_decoder_tb -Wno-TIMESCALEMOD --trace \

#run simulation
./obj_dir/Varcabuco_decoder_tb 
#if any argument open  gui
if [ ! -z $1 ]; then
  gtkwave decoder.vcd
fi

