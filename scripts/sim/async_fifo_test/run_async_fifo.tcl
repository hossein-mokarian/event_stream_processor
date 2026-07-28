create_project -force async_fifo_test async_fifo_test -part xc7a35tcpg236-1
add_files -norecurse ../../../rtl/cdc/async_fifo.sv
add_files -fileset sim_1 ../../../tb/unit/tb_async_fifo.sv
set_property top tb_async_fifo [get_filesets sim_1]
launch_simulation
run 2us
close_sim
