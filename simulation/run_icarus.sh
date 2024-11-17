#!/bin/bash

rm -f *.sim *.vcd
#list all
iverilog -g2012 -s arcabuco_system_tb -c file_list.txt -o arcabuco.sim
#run simulation
./arcabuco.sim
#if any argument open  gui
if [ ! -z $1 ]; then
  gtkwave arcabuco_sim.vcd
fi

