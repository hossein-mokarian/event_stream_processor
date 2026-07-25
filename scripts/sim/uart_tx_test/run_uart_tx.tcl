create_project -force uart_tx_test uart_tx_test -part xc7a35tcpg236-1
add_files -norecurse ../../../rtl/uart/uart_tx.sv
add_files -fileset sim_1 ../../../tb/unit/tb_uart_tx.sv
set_property top tb_uart_tx [get_filesets sim_1]
launch_simulation
run 3ms
close_sim
