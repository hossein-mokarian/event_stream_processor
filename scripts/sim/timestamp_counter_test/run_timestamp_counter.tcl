create_project -force timestamp_counter_test timestamp_counter_test -part xc7a35tcpg236-1
add_files -norecurse ../../../rtl/timestamp/timestamp_counter.sv
add_files -fileset sim_1 ../../../tb/unit/tb_timestamp_counter.sv
set_property top tb_timestamp_counter [get_filesets sim_1]
launch_simulation
run 10us
close_sim
