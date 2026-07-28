`timescale 1ns/1ps


module tb_async_fifo;

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 4;
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;

    localparam WR_CLK_PERIOD = 10; // Write clk freq ==> T = 10 * 1ns = 10ns ---> f = 1/T = 1 / 10ns = 100 MHz
    localparam RD_CLK_PERIOD = 20; // Read  clk freq ==> T = 20 * 1ns = 20ns ---> f = 1/T = 1 / 20ns = 50  MHz

    localparam RESET_TIME = 50;


    //--- DUT Signals : Write Domain ---
    logic wclk_in;
    logic wrst_n;
    logic [DATA_WIDTH - 1 : 0] wdata_in;
    logic wen_in;
    logic wfull_out;

    //--- DUT Signals : Read Domain ---
    logic rclk_in;
    logic rrst_n;
    logic ren_in;
    logic [DATA_WIDTH - 1 : 0] rdata_out;
    logic rvalid_out;
    logic rempty_out;

    //--- Verification VARs ---
    logic [DATA_WIDTH - 1 : 0] ref_queue [$];
    logic [DATA_WIDTH - 1 : 0] expected_data;
    integer writes_done;
    integer reads_done;
    integer errors;
    integer test_num;


    //--- Module Instance ---
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        //--- Write Domain ---
        .wclk_in(wclk_in),
        .wrst_n(wrst_n),
        .wdata_in(wdata_in),
        .wen_in(wen_in),
        .wfull_out(wfull_out),

        //--- Read Domain ---
        .rclk_in(rclk_in),
        .rrst_n(rrst_n),
        .ren_in(ren_in),
        .rdata_out(rdata_out),
        .rvalid_out(rvalid_out),
        .rempty_out(rempty_out)
    );

    //--- Clock generation ---
    initial wclk_in = 0;
    always #(WR_CLK_PERIOD / 2) wclk_in = ~wclk_in;

    initial rclk_in = 0;
    always #(RD_CLK_PERIOD / 2) rclk_in = ~rclk_in;


    //--- Push written data to queue ---
    always @(posedge wclk_in) begin
        if (wrst_n && wen_in && !wfull_out) begin
            ref_queue.push_back(wdata_in);
            writes_done <= writes_done + 1;
        end
    end

    //--- Main Test ---
    initial begin
        
        //--- Init vars & signals ---
        errors = 0;

        wdata_in = '0;
        wen_in = 1'b0;
        ren_in = 1'b0;

        //--- Show test bench info in the terminal ---
        $display("==== Async FIFO Test ===");
        $display("FIFO Depth: %d, Data Width: %d", FIFO_DEPTH, DATA_WIDTH);
        $display("Write Clock  Freq: %d MHz, Read Clock Freq: %d MHz", 1000/WR_CLK_PERIOD, 1000/RD_CLK_PERIOD);

        //--- Reset  ---
        wrst_n = 1'b0;
        rrst_n = 1'b0;
        repeat(RESET_TIME) @(posedge wclk_in);
        wrst_n = 1;
        repeat(RESET_TIME / RD_CLK_PERIOD / WR_CLK_PERIOD) @(posedge rclk_in);
        rrst_n = 1;

        //--- Delay ---
        repeat(5) @(posedge wclk_in);

        //--- Test 1: ? ----
        $display("\n  TEST 1: basic write/read operation");
        fork
            begin
                wen_in = 1'b0;
                @(negedge wclk_in);
                wdata_in = 'h1234;
                wen_in = 1'b1;
                @(negedge wclk_in)
                wen_in = 1'b0;
            end
            begin
                ren_in = 1'b0;
                repeat(10) @(negedge rclk_in);
                while (rempty_out) @(negedge rclk_in);
                ren_in = 1'b1;
                @(negedge rclk_in);
                ren_in = 1'b0;
            end
        join

        //--- Summary ---
        $display("\n=== Test summary ===");
        if (errors == 0) begin
            $display("ALL TESTS PASSED!");
        end else  begin
            $display("FAILED: %0d errors, %0d items remain in queue", errors, ref_queue.size());
        end

        $finish;
    end

    //--- SVA ---
    property full_wr_req;
        @(posedge wclk_in) disable iff (!wrst_n)
        wfull_out |-> !wen_in;
    endproperty

    property empty_rd_req;
        @(posedge rclk_in) disable iff (!rrst_n)
        rempty_out |-> !ren_in;
    endproperty

    assert property (full_wr_req)
        else $error("Write request is asserted when the buffer is full!");

    assert property (empty_rd_req)
        else $error("Read requst is asserted when the buffer is empty!");
        

    //--- Timeout watchdog ---
    initial begin
        #5_000_000
        $display("FATAL: Simulation Timeout Error!");
        $finish;
    end

    //--- Save simulation data ---
    initial begin
        $dumpfile("tb_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
    end
    
endmodule
