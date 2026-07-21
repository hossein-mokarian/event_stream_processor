`timescale 1ns / 1ps

module tb_blinker;
    logic clk;
    logic rst_n;
    logic led;

    // Instantiate DUT
    blinker #(
        .CLK_FREQ_HZ(1_000),
        .BLINK_HZ(10)
    ) dut (
        .clk  (clk),
        .rst_n(rst_n),
        .led  (led)
    );

    // 50 MHz clock generation (period = 20 ns)
    always #10 clk = ~clk;

    // Simple check: just run for a few seconds and observe
    initial begin
        $display("=== Blinker Testbench ===");
        clk   = 0;
        rst_n = 0;

        // Hold reset for 100 ns
        #100;
        rst_n = 1;

        // Run for 3 seconds (enough to see at least one full blink cycle)
        #3_000_000_000;

        $display("Simulation finished.");
        $finish;
    end

    // Optional: dump VCD for waveform viewing
    initial begin
        $dumpfile("tb_blinker.vcd");
        $dumpvars(0, tb_blinker);
    end
endmodule
