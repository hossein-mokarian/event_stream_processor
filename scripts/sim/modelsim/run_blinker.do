# scripts/sim/run_blinker.do

# cd scripts/sim
# vsim -do run_blinker.do

vlib work
vlog -sv ../rtl/top/blinker.sv
vlog -sv ../tb/unit/tb_blinker.sv
vsim -c -do "run -all; quit" tb_blinker
