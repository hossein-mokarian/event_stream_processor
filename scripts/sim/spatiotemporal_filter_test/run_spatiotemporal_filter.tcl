create_project -force spatiotemporal_filter_test spatiotemporal_filter_test -part xc7a35tcpg236-1
add_files -norecurse ../../../rtl/filter/spatiotemporal_filter.sv \
                     ../../../rtl/filter/ref_filter.sv
add_files -fileset sim_1 ../../../tb/unit/tb_spatiotemporal_filter.sv
set_property top tb_spatiotemporal_filter [get_filesets sim_1]
