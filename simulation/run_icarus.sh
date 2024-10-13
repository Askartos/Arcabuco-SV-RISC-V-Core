#!/bin/bash

rm -f *.out *.vcd
#list all
iverilog -g2012 ../src/tb/arcabuco_tb.v
#run simulation
./a.out
#if any argument open  gui

if [ ! -z $1 ]; then
  gtkwave arcabuco_sim.vcd
fi

