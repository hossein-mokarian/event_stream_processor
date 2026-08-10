create_project -force cdc_integration_test cdc_integration_test -part xc7a35tcpg236-1
add_files -norecurse ../../../rtl/event_generator/aer_pixel.sv \
                     ../../../rtl/event_generator/rr_arbiter.sv \
                     ../../../rtl/event_generator/aer_arbiter.sv \
                     ../../../rtl/event_generator/aer_pixel_array.sv \
                     ../../../rtl/event_generator/stimulus_generator.sv \
                     ../../../rtl/event_generator/event_generator_top.sv \
                     ../../../rtl/cdc/async_fifo.sv \
                     ../../../rtl/cdc/event_cdc_bridge.sv
add_files -fileset sim_1 ../../../tb/unit/tb_cdc_integration.sv
set_property top tb_cdc_integration [get_filesets sim_1]
