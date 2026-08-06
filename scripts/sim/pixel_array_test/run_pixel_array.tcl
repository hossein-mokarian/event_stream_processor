create_project -force pixel_array_test pixel_array_test -part xc7a35tcpg236-1
add_files -norecurse ../../../rtl/event_generator/aer_pixel.sv \
                     ../../../rtl/event_generator/rr_arbiter.sv \
                     ../../../rtl/event_generator/aer_arbiter.sv \
                     ../../../rtl/event_generator/aer_pixel_array.sv
add_files -fileset sim_1 ../../../tb/unit/tb_pixel_array.sv
set_property top tb_pixel_array [get_filesets sim_1]

