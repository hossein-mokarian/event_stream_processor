create_project -force pipeline_test pipeline_test -part xc7a35tcpg236-1

add_files -norecurse ../../../rtl/event_generator/stimulus_generator.sv \
                     ../../../rtl/event_generator/rr_arbiter.sv \
                     ../../../rtl/event_generator/aer_arbiter.sv \
                     ../../../rtl/event_generator/aer_pixel.sv \
                     ../../../rtl/event_generator/aer_pixel_array.sv \
                     ../../../rtl/event_generator/event_generator_top.sv \
                     ../../../rtl/cdc/async_fifo.sv \
                     ../../../rtl/cdc/event_cdc_bridge.sv \
                     ../../../rtl/timestamp/timestamp_counter.sv \
                     ../../../rtl/filter/spatiotemporal_filter.sv \
                     ../../../rtl/filter/filter_v2.sv \
                     ../../../rtl/filter/filter_subsystem.sv \
                     ../../../rtl/top/event_pipeline.sv

add_files -fileset sim_1 ../../../tb/integration/tb_pipeline.sv

set_property top tb_pipeline [get_filesets sim_1]

close_project
