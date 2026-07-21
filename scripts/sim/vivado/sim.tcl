# vivado -mode batch -source sim.tcl

open_project blinker_test/blinker_test.xpr
# current_sim [current_sim -all]
# relaunch_sim
launch_simulation
# restart
run 30ms

# gtkwave .\blinker_test\blinker_test.sim\sim_1\behav\xsim\tb_blinker.vcd
