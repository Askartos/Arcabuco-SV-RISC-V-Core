#!/bin/bash

./clean.sh


#list all
verilator --binary \
-f file_list.txt \
--top arcabuco_system_tb -Wno-TIMESCALEMOD -Wno-fatal --trace \

#run simulation
./obj_dir/Varcabuco_system_tb 
#if any argument open  gui
if [ ! -z $1 ]; then
  gtkwave arcabuco_sim.vcd
fi

