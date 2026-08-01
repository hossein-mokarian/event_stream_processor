create_project -force aer_pixel_test aer_pixel_test -part xc7a35tcpg236-1

add_files -norecurse ../../../rtl/event_generator/aer_pixel.sv
add_files -fileset sim_1 ../../../tb/unit/tb_aer_pixel.sv

set_property top tb_aer_pixel [get_filesets sim_1]

# update_compile_order -fileset sources_1
# update_compile_order -fileset sim_1

# launch_simulation
# run 2us

# close_sim
