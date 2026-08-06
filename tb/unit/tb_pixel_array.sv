`timescale 1ns/1ps


module tb_pixel_array;

    localparam ARRAY_SIZE_X = 4; // 16;
    localparam ARRAY_SIZE_Y = 4; // 16;
    localparam ADDR_WIDTH = 16;

    localparam CLK_FREQ_HZ = 50_000_000;
    localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ_HZ;

    localparam PIXEL_COUNT = ARRAY_SIZE_X * ARRAY_SIZE_Y;


    logic clk;
    logic rst_n;

    logic [0 : PIXEL_COUNT - 1] stim_in;
    logic aer_req_out;
    logic [ADDR_WIDTH - 1 : 0] aer_addr_out;
    logic aer_pol_out;
    logic aer_ack_in;

    aer_pixel_array #(
        .ARRAY_SIZE_X(ARRAY_SIZE_X),
        .ARRAY_SIZE_Y(ARRAY_SIZE_Y),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .stim_in(stim_in),

        .aer_req_out(aer_req_out),
        .aer_addr_out(aer_addr_out),
        .aer_pol_out(aer_pol_out),
        .aer_ack_in(aer_ack_in)
    );

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    //--- Maint Test ---
    initial begin
        //--- Inittial values ---
        stim_in = {PIXEL_COUNT{1'b0}};

        aer_ack_in = 1'b0;

        //--- Reset ---
        rst_n = 1'b0;
        repeat(10) @(posedge clk);
        rst_n = 1'b1;

        //--- Test 1 ---
        repeat(10) @(negedge clk);
        stim_in[0] = 1'b1;
        @(negedge clk);
        stim_in[0] = 1'b0;
        repeat(2) @(negedge clk);
        aer_ack_in = 1'b1;

        while (aer_req_out) @(negedge clk);
        aer_ack_in = 1'b0;

        //--- Test 2 ---
        repeat(10) @(negedge clk);
        stim_in[0] = 1'b1;
        stim_in[1] = 1'b1;
        stim_in[2] = 1'b1;
        @(negedge clk);
        stim_in[0] = 1'b0;
        stim_in[1] = 1'b0;
        stim_in[2] = 1'b0;
        repeat(2) @(negedge clk);
        aer_ack_in = 1'b1;
        
        while (aer_req_out) @(negedge clk);
        aer_ack_in = 1'b0;

        repeat(10) @(negedge clk);
        aer_ack_in = 1'b1;

        while (aer_req_out) @(negedge clk);
        aer_ack_in = 1'b0;

        repeat(10) @(negedge clk);
        aer_ack_in = 1'b1;

        while (aer_req_out) @(negedge clk);
        aer_ack_in = 1'b0;

        #10

        $finish;

    end

    //--- Simulation timeout watchdog ---
    initial begin
        #5_000_000
        $display("Warninig: Simulation Timeout!");
        $finish;
    end

    //--- Save results ---
    initial begin
        $dumpfile("tb_pixel_array.vcd");
        $dumpvars(0, tb_pixel_array);
    end

endmodule
