`timescale 1ns/1ps


module tb_timestamp_counter;

    localparam INPUT_CLK_FREQ_HZ = 50_000_000;

    logic clk;
    logic rst_n;
    logic [31 : 0] timestamp;
    logic tick_1us;

    timestamp_counter #(
        .INPUT_CLK_FREQ_HZ(INPUT_CLK_FREQ_HZ)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .timestamp(timestamp),
        .tick_1us(tick_1us)
    );

    initial clk = 0;
    always #(10) clk = ~clk; // freq = 1 / 20ns = 1_000_000_000 / 20 = 50_000_000 MHz

    initial begin

        //--- Reset ---
        rst_n = 1'b0;
        repeat(10) @(posedge clk);
        rst_n = 1'b1;

        //--- Test 1 ---

        repeat(10 * 50) @(posedge clk);
        $finish;

    end

    //--- SVA ---
    property one_cycle_tick_1us;
        @(posedge clk) disable iff (!rst_n)
        tick_1us |=> !tick_1us;
    endproperty

    assert property (one_cycle_tick_1us) 
        else   $error("The tick_1us is more than one cycle!");

    //--- Simulation timeout watchdog ---
    initial begin
        #5_000_000
        $display("Warning: Simulation Timeour!");
        $finish;
    end

    //--- Save results ---
    initial begin
        $dumpfile("tb_timestamp_counter.vcd");
        $dumpvars(0, tb_timestamp_counter);
    end

endmodule
