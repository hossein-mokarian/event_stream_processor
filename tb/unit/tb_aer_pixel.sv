`timescale 1ns/1ps


module tb_aer_pixel;

    localparam PIXEL_X = 1;
    localparam PIXEL_Y = 2;
    localparam ADDR_WIDTH = 16;

    localparam CLK_FREQ_HZ = 50_0000_000;
    localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ_HZ;

    logic clk;
    logic rst_n;
    logic stimulus_in;
    logic req_out;
    logic [ADDR_WIDTH - 1 : 0] pixel_addr_out;
    logic pol_out;
    logic ack_in;

    aer_pixel #(
        .PIXEL_X(PIXEL_X),
        .PIXEL_Y(PIXEL_Y),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .stimulus_in(stimulus_in),
        .req_out(req_out),
        .pixel_addr_out(pixel_addr_out),
        .pol_out(pol_out),
        .ack_in(ack_in)
    );

    //--- CLK generation ---
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    //--- Main Teat ---
    initial begin
        
        //--- Initial Values ---
        stimulus_in = 1'b0;
        ack_in = 1'b0;
        
        //--- Reset ---
        rst_n = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk);

        //--- Test 1 ---
        repeat(10) @(negedge clk);
        stimulus_in = 1'b1;
        @(negedge clk);
        stimulus_in = 1'b0;

        repeat(5) @(negedge clk);
        ack_in = 1'b1;
        repeat(5) @(negedge clk);
        ack_in = 1'b0;

        #100

        $finish;

    end

    //--- SVA ---
    property stimulus_req_p;
        @(posedge clk) disable iff (!rst_n)
        stimulus_in |=> req_out;
    endproperty

    assert property (stimulus_req_p) 
        else $error("REQ is not asserted after asserting stimulus_in!");

    property low_ack_req_p;
        @(posedge clk) disable iff (!rst_n)
        req_out |-> ack_in |=> !ack_in |=> !req_out;
    endproperty

    assert property (low_ack_req_p)
        else $error("REQ is not deasserted after low ACK!");

    property check_req_state_p;
        @(posedge clk) disable iff (!rst_n)
        stimulus_in |=> dut.state == dut.REQUEST;
    endproperty

    assert property (check_req_state_p)
        else $error("No transition to REQ state after high stimulus_in!");
    
    property wait_for_low_ack_p;
        @(posedge clk) disable iff (!rst_n)
        (ack_in && dut.state == dut.WAIT_FOR_LOW_ACK) |=> $stable(dut.state);
    endproperty

    assert property (wait_for_low_ack_p)
        else $error("ACK is high, but FSM state is changed!");
    
    property return_to_idle_p;
        @(posedge clk) disable iff (!rst_n)
        (!ack_in && req_out) ##1 (!ack_in && !req_out) |=> dut.state == dut.IDLE;
    endproperty

    assert property (return_to_idle_p)
        else $error("The FSM does not return to IDLE state after full handshake!");

    //--- Simulation timeout watchdog
    initial begin
        #5_0000_000
        $display("Warning: Simulation Timeout!");
        $finish;
    end

    //--- Save results ---
    initial begin
        $dumpfile("tb_aer_pixel.vcd");
        $dumpvars(0, tb_aer_pixel);
    end
    
endmodule
