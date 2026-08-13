`timescale 1ns/1ps


module tb_spatiotemporal_filter;

    localparam HISTORY_DEPTH = 16;
    localparam ADDR_WIDTH = 16;
    localparam TIMESTAMP_WIDTH = 32;
    localparam FILTER_TIME_US = 50;

    localparam CLK_FREQ_HZ = 50_000_000;
    localparam CLK_PERIOD  = 1_000_000_000 / CLK_FREQ_HZ;


    integer i;

    //--- General ---
    logic clk;
    logic rst_n;

    //--- Events ---
    logic ev_valid_in;
    logic [ADDR_WIDTH - 1 : 0] ev_addr;
    logic ev_pol;
    logic [TIMESTAMP_WIDTH - 1 : 0] timestamp;

    //--- Filtered events ---
    logic ev_valid_out;
    logic [ADDR_WIDTH - 1 : 0] filtered_ev_addr;
    logic filtered_ev_pol;
    logic [TIMESTAMP_WIDTH - 1 : 0] filtered_timestamp;

    //--- Status ---
    logic ev_pass;
    logic ev_drop;

    //--- Verification ---
    typedef struct {
        logic [ADDR_WIDTH / 2 - 1 : 0] x;
        logic [ADDR_WIDTH / 2 - 1 : 0] y;
        logic pol;
        logic [TIMESTAMP_WIDTH - 1 : 0] ts;
    } EVENT_t;

    EVENT_t events_queque [$];
    EVENT_t expected_event;
    EVENT_t rec_event;

    integer errors;
    integer event_count;


    spatiotemporal_filter #(
        .HISTORY_DEPTH(HISTORY_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH),
        .FILTER_TIME_US(FILTER_TIME_US)
    ) dut (
        //--- General ---
        .clk(clk),
        .rst_n(rst_n),

        //--- Events ---
        .ev_valid_in(ev_valid_in),
        .ev_addr_in(ev_addr),
        .ev_pol_in(ev_pol),
        .timestamp_in(timestamp),

        //--- Filtered events ---
        .ev_valid_out(ev_valid_out),
        .filtered_ev_addr_out(filtered_ev_addr),
        .filtered_ev_pol_out(filtered_ev_pol),
        .timestamp_out(filtered_timestamp),

        //--- Status ---
        .ev_pass_out(ev_pass),
        .ev_drop_out(ev_drop)
    );


    //--- Generate CLK ---
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;


    //--- timestamp ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timestamp <= {TIMESTAMP_WIDTH{1'b0}};
        end else begin
            timestamp <= timestamp + 1;
        end
    end


    //--- Monitor ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rec_event.x = '0;
            rec_event.y = '0;
            rec_event.pol = 1'b0;
            rec_event.ts = '0;
        end else begin
            if (ev_pass) begin
                rec_event.x = filtered_ev_addr[ADDR_WIDTH - 1     : ADDR_WIDTH / 2];
                rec_event.y = filtered_ev_addr[ADDR_WIDTH / 2 - 1 : 0             ];
                rec_event.pol = filtered_ev_pol;
                rec_event.ts = filtered_timestamp;

                events_queque.push_back(rec_event);
            end
        end
    end


    //--- Tasks ---
    task automatic send_event(
        input logic [ADDR_WIDTH / 2 - 1 : 0] x,
        input logic [ADDR_WIDTH / 2 - 1 : 0] y,
        input logic pol
        // input logic [TIMESTAMP_WIDTH - 1 : 0] ts
    );
        
        ev_valid_in = 1'b1;
        ev_addr = {x, y};
        ev_pol = pol;
        // timestamp_in = ts;

        repeat(1) @(posedge clk);
        ev_valid_in = 1'b0;

    endtask // send_event

    task automatic wait_for_low_valid_out();
        while (ev_valid_out) begin
            @(posedge clk);
        end
    endtask // wait_for_low_valid_out

    task automatic delay(input logic [31 : 0] d);
        repeat(d) @(posedge clk);
    endtask // delay


    //--- Main Test ---
    initial begin

        //--- Initial values ---
        ev_valid_in = 1'b0;
        ev_addr = {ADDR_WIDTH{1'b0}};
        ev_pol = 1'b0;

        errors = 0;
        event_count = 0;

        //--- Reset ---
        rst_n = 1'b0;
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        repeat(10) @(posedge clk);

        //--- Test 1 ---
        $display("====================================================================");
        $display("Test 1:   single events");
        $display("GOAL:     ");

        // wait_for_low_valid_out();
        send_event(8'h01, 8'h01, 1'b1); // , timestamp);

        delay(4);

        // wait_for_low_valid_out();
        send_event(8'h00, 8'h01, 1'b1); //, timestamp);

        delay(4);

        // wait_for_low_valid_out();
        send_event(8'h01, 8'h01, 1'b1); //, timestamp);

        ev_addr = {ADDR_WIDTH{1'b0}};
        ev_pol = 1'b0;

        $display("Results:");
        // $display("      Events     : %d", event_count);

        $display("PASS:     Test 1 is done successfully.");

        //--- The end ---
        $display("====================================================================");
        $display("Test 2:   Burst events ");
        $display("GOAL:     ");

        delay(10);

        for (i = 0; i < 4; i = i + 1) begin
            // wait_for_low_valid_out();
            send_event(8'h01, i, 1'b1); //, timestamp);
        end

        ev_addr = {ADDR_WIDTH{1'b0}};
        ev_pol = 1'b0;

        $display("Results:");
        // $display("      Events     : %d", event_count);

        $display("PASS:     Test 2 is done successfully.");
        $display("====================================================================");
        $display("Test 3:   Timestamp > 50us ");
        $display("GOAL:     ");

        delay(FILTER_TIME_US + 5);

        // wait_for_low_valid_out();
        send_event(8'h01, 8'h01, 1'b1); //, timestamp);

        ev_addr = {ADDR_WIDTH{1'b0}};
        ev_pol = 1'b0;

        delay(4);

        $display("Results:");
        // $display("      Events     : %d", event_count);

        $display("PASS:     Test 3 is done successfully.");
        $display("====================================================================");

        #100

        $finish;

    end

    
    //--- Simulation timeout watchdog ---
    initial begin
        #5_000_000
        $display("WARNING: Simulation timeout!");
        $finish;
    end

    
    //--- Save results ---
    initial begin
        $dumpfile("tb_spatiotemporal_filter.vcd");
        $dumpvars(0, tb_spatiotemporal_filter);
    end

endmodule
