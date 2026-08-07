create_project -force event_generator_test event_generator_test -part xc7a35tcpg236-1
add_files -norecurse ../../../rtl/event_generator/aer_pixel.sv \
                     ../../../rtl/event_generator/rr_arbiter.sv \
                     ../../../rtl/event_generator/aer_arbiter.sv \
                     ../../../rtl/event_generator/aer_pixel_array.sv \
                     ../../../rtl/event_generator/stimulus_generator.sv \
                     ../../../rtl/event_generator/event_generator_top.sv
add_files -fileset sim_1 ../../../tb/unit/tb_event_generator.sv                     
set_property top tb_event_generator [get_filesets sim_1]
