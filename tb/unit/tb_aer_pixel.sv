`timescale 1ns/1ps


module tb_aer_pixel;

    localparam PIXEL_X = 1;
    localparam PIXEL_Y = 2;
    localparam ADDR_WIDTH = 16;

    localparam CLK_FREQ_HZ = 50_0000_000;
    localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ_HZ;

    logic clk;
    logic rst_n;
    logic stimulus;
    logic req;
    logic [ADDR_WIDTH - 1 : 0] pixel_addr;
    logic pol;
    logic ack;

    aer_pixel #(
        .PIXEL_X(PIXEL_X),
        .PIXEL_Y(PIXEL_Y),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .stimulus(stimulus),
        .req(req),
        .pixel_addr(pixel_addr),
        .pol(pol),
        .ack(ack)
    );

    //--- CLK generation ---
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    //--- Main Teat ---
    initial begin
        
        //--- Initial Values ---
        stimulus = 1'b0;
        ack = 1'b0;
        
        //--- Reset ---
        rst_n = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk);

        //--- Test 1 ---
        repeat(10) @(negedge clk);
        stimulus = 1'b1;
        @(negedge clk);
        stimulus = 1'b0;

        repeat(5) @(negedge clk);
        ack = 1'b1;
        repeat(5) @(negedge clk);
        ack = 1'b0;

        #100

        $finish;

    end

    //--- SVA ---
    property stimulus_req_p;
        @(posedge clk) disable iff (!rst_n)
        stimulus |=> req;
    endproperty

    assert property (stimulus_req_p) 
        else $error("REQ is not asserted after asserting stimulus!");

    property low_ack_req_p;
        @(posedge clk) disable iff (!rst_n)
        req |-> ack |=> !ack |=> !req;
    endproperty

    assert property (low_ack_req_p)
        else $error("REQ is not deasserted after low ACK!");

    property check_req_state_p;
        @(posedge clk) disable iff (!rst_n)
        stimulus |=> dut.state == dut.REQUEST;
    endproperty

    assert property (check_req_state_p)
        else $error("No transition to REQ state after high stimulus!");
    
    property wait_for_low_ack_p;
        @(posedge clk) disable iff (!rst_n)
        (ack && dut.state == dut.WAIT_FOR_LOW_ACK) |=> $stable(dut.state);
    endproperty

    assert property (wait_for_low_ack_p)
        else $error("ACK is high, but FSM state is changed!");
    
    property return_to_idle_p;
        @(posedge clk) disable iff (!rst_n)
        (!ack && req) ##1 (!ack && !req) |=> dut.state == dut.IDLE;
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
