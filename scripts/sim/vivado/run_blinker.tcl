# scripts/sim/run_blinker.tcl

# cd scripts/sim/vivado
# "D:\ProgramFiles\Xilinx\Vivado\2019.1\settings64.bat"
# vivado -mode batch -source run_blinker.tcl

create_project -force blinker_test blinker_test -part xc7a35tcpg236-1
add_files -norecurse ../../../rtl/top/blinker.sv
add_files -fileset sim_1 -norecurse ../../../tb/unit/tb_blinker.sv
set_property top tb_blinker [get_filesets sim_1]
launch_simulation
run 3ms
close_sim
