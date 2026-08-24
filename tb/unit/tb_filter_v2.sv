`timescale 1ns/1ps


module tb_filter_v2;

    localparam CLK_FREQ_HZ = 50_000_000;
    localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ_HZ;
    localparam HISTORY_DEPTH = 64;
    localparam ADDR_WIDTH = 16;
    localparam TIMESTAMP_WIDTH = 32;
    localparam FILTER_TIME_US = 50;


    //--- General ---
    logic clk;
    logic rst_n;

    //--- Events ---
    logic ev_valid_in;
    logic [ADDR_WIDTH - 1 : 0] ev_addr_in;
    logic ev_pol_in;

    //--- Filtered events ---
    logic ev_valid_out;
    logic [ADDR_WIDTH - 1 : 0] filtered_ev_addr_out;
    logic filtered_ev_pol_out;
    logic [TIMESTAMP_WIDTH - 1 : 0] timestamp_out;

    //--- Status ---
    logic ev_pass_out;
    logic ev_drop_out;


    filter_subsystem #(
        .INPUT_CLK_FREQ_HZ(CLK_FREQ_HZ),
        .HISTORY_DEPTH(HISTORY_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH),
        .FILTER_TIME_US(FILTER_TIME_US)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        //--- Events ---
        .ev_valid_in(ev_valid_in),
        .ev_addr_in(ev_addr_in),
        .ev_pol_in(ev_pol_in),
        // .timestamp_in(),

        //--- Filtered events ---
        .ev_valid_out(ev_valid_out),
        .filtered_ev_addr_out(filtered_ev_addr_out),
        .filtered_ev_pol_out(filtered_ev_pol_out),
        .timestamp_out(timestamp_out),

        //--- Status ---
        .ev_pass_out(ev_pass_out),
        .ev_drop_out(ev_drop_out)
    );


    //--- Generate CLK ---
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;


    //--- Main Test ---
    initial begin
        //--- Initial values ---

        //--- Reset ---
        rst_n = 1'b0;
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        repeat(10) @(posedge clk);

        //--- test 1 ---


        #100
        $finish;
    end

    //--- Simulation Timeout Watchdog ---
    initial begin
        #5_000_000
        $display("WARNING: Simulation Timeout!");
        $finish;
    end

    //--- Save results ---
    initial begin
        $dumpfile("tb_filter_v2.vcd");
        $dumpvars(0, tb_filter_v2);
    end

endmodule
