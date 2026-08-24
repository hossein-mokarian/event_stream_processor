create_project -force filter_v2_test filter_v2_test -part xc7a35tcpg236-1

add_files -norecurse [list \
    "../../../rtl/timestamp/timestamp_counter.sv" \
    "../../../rtl/filter/history_buffer.sv" \
    "../../../rtl/filter/filter_v2.sv" \
    "../../../rtl/filter/filter_subsystem.sv" \
]

add_files -fileset sim_1 ../../../tb/unit/tb_filter_v2.sv

set_property top tb_filter_v2 [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

close_project
