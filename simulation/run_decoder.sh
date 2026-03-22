#!/bin/bash

./clean.sh 

#list all
iverilog -g2012 -s arcabuco_decoder_tb \
../src/rtl/arcabuco_core/arcabuco_core_pack.sv \
../src/rtl/arcabuco_core/arcabuco_decoder.sv \
../src/tb/decoder_tb.sv \
-o decoder.sim
#run simulation
./decoder.sim
#if any argument open  gui
if [ ! -z $1 ]; then
  gtkwave decoder.vcd
fi

