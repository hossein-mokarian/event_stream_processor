`timescale 1ns/1ps


module tb_pipeline;

    localparam PIX_CLK_FREQ_HZ = 50_000_000;
    localparam PIX_CLK_PERIOD  = 1_000_000_000 / PIX_CLK_FREQ_HZ;

    localparam SYS_CLK_FREQ_HZ = 100_000_000;
    localparam SYS_CLK_PERIOD  = 1_000_000_000 / SYS_CLK_FREQ_HZ;

    //--- Event generator ---
    localparam ARRAY_SIZE_X = 16;
    localparam ARRAY_SIZE_Y = 16;
    localparam ADDR_WIDTH   = 16;

    //--- CDC ---
    localparam DATA_WIDTH      = 32;
    localparam FIFO_ADDR_WIDTH = 4;

    //--- Filter ---
    localparam INPUT_CLK_FREQ_HZ = SYS_CLK_FREQ_HZ;
    localparam HISTORY_DEPTH     = 16;
    // localparam ADDR_WIDTH        = 16;
    localparam TIMESTAMP_WIDTH   = 32;
    localparam FILTER_TIME_US    = 50;


    //--- General ---
    logic pix_clk;
    logic pix_rst_n;

    logic sys_clk;
    logic sys_rst_n;

    logic [1 : 0] mode_in;
    logic [7 : 0] param_0_in;
    logic [7 : 0] param_1_in;
    logic enable_in;
    logic event_pending;

    logic ev_valid;
    logic [ADDR_WIDTH - 1 : 0] filtered_ev_addr;
    logic filtered_ev_pol;
    logic [TIMESTAMP_WIDTH - 1 : 0] ev_timestamp;

    logic ev_pass;
    logic ev_drop;


    event_pipeline #(
        //--- Event generator ---
        .ARRAY_SIZE_X(ARRAY_SIZE_X),
        .ARRAY_SIZE_Y(ARRAY_SIZE_Y),
        .ADDR_WIDTH(ADDR_WIDTH),

        //--- CDC ---
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH),

        //--- Filter ---
        .INPUT_CLK_FREQ_HZ(INPUT_CLK_FREQ_HZ),
        .HISTORY_DEPTH(HISTORY_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH),
        .FILTER_TIME_US(FILTER_TIME_US)
    ) dut (
        //--- Genearl ---
        .pix_clk(pix_clk),
        .pix_rst_n(pix_rst_n),

        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),

        //--- Event generator ---
        .mode_in(mode_in),
        .param_0_in(param_0_in),
        .param_1_in(param_1_in),
        .enable_in(enable_in),

        .event_pending_out(event_pending),

        //--- CDC ---

        //--- Filter ---
        .ev_valid_out(ev_valid),
        .filtered_ev_addr_out(filtered_ev_addr),
        .filtered_ev_pol_out(filtered_ev_pol),
        .timestamp_out(ev_timestamp),

        .ev_pass_out(ev_pass),
        .ev_drop_out(ev_drop)
    );

    
    //--- Generate CLK ---
    initial pix_clk = 0;
    always #(PIX_CLK_PERIOD / 2) pix_clk = ~pix_clk;

    initial sys_clk = 0;
    always #(SYS_CLK_PERIOD / 2) sys_clk = ~sys_clk;


    //--- Tasks ---
    task automatic set_mode(
        input logic [1 : 0] m,
        input logic [7 : 0] p0,
        input logic [7 : 0] p1
    );
        mode_in = m;
        param_0_in = p0;
        param_1_in = p1;
    endtask //set_mode

    task automatic set_enable(input logic en);
        enable_in = en;
        repeat(3) @(negedge pix_clk);
    endtask // set_enable

    task automatic wait_for_pending_events(input int nb_of_ev = 1000); // Todo: change the task name

        automatic int counter = 0;
        automatic int timeout = 16;
        
        while(event_pending) @(negedge pix_clk)

        while(counter < nb_of_ev) begin
            
            timeout = 16;
            while (timeout > 0 && !event_pending) begin
                @(negedge pix_clk);
                timeout--;
            end
            
            counter++;
        end

    endtask // drop_events


    //--- Main Test ---
    initial begin
        
        //--- Initial values ---
        mode_in = 2'b00; // IDLE
        param_0_in = 8'h00;
        param_1_in = 8'h00;
        enable_in = 1'b0; // Disable


        //--- Reset ---
        fork
            begin
                pix_rst_n = 1'b0;
                repeat(10) @(posedge pix_clk);
                pix_rst_n = 1'b1;
                repeat(10) @(posedge pix_clk);
            end

            begin
                sys_rst_n = 1'b0;
                repeat(10) @(posedge sys_clk);
                sys_rst_n = 1'b1;
                repeat(10) @(posedge sys_clk);
            end
        join

        //--- Test 1 ---
        set_mode(2'b01, 8'h4, 8'h01); // EDGE / periods : 4 / Dir: Horizontal
        set_enable(1'b1);
        wait_for_pending_events(16);
        set_enable(1'b0);

        #100
        $finish;

    end


    //--- Simulation Timeout Watchdog ---
    initial begin
        #5_000_000
        $display("WARNING: Simulation Timeout!");
        $finish;
    end


    //--- Save Results ---
    initial begin
        $dumpfile("tb_pipeline.vcd");
        $dumpvars(0, tb_pipeline);
    end

endmodule
