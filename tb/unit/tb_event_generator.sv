`timescale 1ns/1ps

module tb_event_generator;

    localparam CLK_FREQ_KZ = 50_000_000;
    localparam CLK_PRIEOD  = 1_000_000_000 / CLK_FREQ_KZ;

    localparam ARRAY_SIZE_X = 4;
    localparam ARRAY_SIZE_Y = 4;
    localparam PIXEL_COUNT = ARRAY_SIZE_X * ARRAY_SIZE_Y;

    localparam ADDR_WIDTH = 16;


    //--- General signals ---
    logic clk;
    logic rst_n;

    //--- Stim generator ---
    logic [1 : 0] mode_in;
    logic [7 : 0] param_0_in;
    logic [7 : 0] param_1_in;
    logic enable_in;

    //--- AER ---
    logic aer_req_out;
    logic [ADDR_WIDTH - 1 : 0] aer_addr_out;
    logic aer_pol_out;
    logic aer_ack_in;

    //--- Status ---
    logic event_pending;

    //--- Verification vars ---
    integer errors;
    integer event_count, on_event, off_event;

    typedef struct {
        logic [ADDR_WIDTH - 1     : ADDR_WIDTH / 2] x;
        logic [ADDR_WIDTH / 2 - 1 : 0             ] y;
        logic pol;
    } EVENT_t;

    EVENT_t event_queue [$];


    event_generator_top #(
        .ARRAY_SIZE_X(ARRAY_SIZE_X),
        .ARRAY_SIZE_Y(ARRAY_SIZE_Y),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        //--- Stim generator ---
        .mode_in(mode_in),
        .param_0_in(param_0_in),
        .param_1_in(param_1_in),
        .enable_in(enable_in),

        //--- AER ---
        .aer_req_out(aer_req_out),
        .aer_addr_out(aer_addr_out),
        .aer_pol_out(aer_pol_out),
        .aer_ack_in(aer_ack_in),

        //--- Status ---
        .event_pending_out(event_pending)
    );


    //--- CLK Generator ---
    initial clk = 0;
    always #(CLK_PRIEOD / 2) clk = ~clk;


    //--- Functions ---
    function reset_event_counters();
        event_count = 0;
        on_event = 0;
        off_event = 0;
    endfunction


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
        repeat(3) @(negedge clk);
    endtask // set_enable

    task automatic ack_event();
        automatic EVENT_t ev;
        
        aer_ack_in = 1'b0;

        //--- Wait to recieve a request ---
        while(!aer_req_out) @(negedge clk);

        ev.x = aer_addr_out[ADDR_WIDTH - 1     : ADDR_WIDTH / 2];
        ev.y = aer_addr_out[ADDR_WIDTH / 2 - 1 : 0             ];
        ev.pol = aer_pol_out;

        event_queue.push_back(ev);

        event_count++;
        if (aer_pol_out) on_event++; else off_event++;

        //--- Handshake ---
        @(negedge clk);
        aer_ack_in = 1'b1;
        @(negedge clk);
        aer_ack_in = 1'b0;

        //--- Wait for low req ---
        while(aer_req_out) @(negedge clk);

    endtask // ack_event;

    task automatic drop_events(input int nb_of_ev = 1000);

        automatic int counter = 0;
        automatic int timeout = 16;
        
        while(counter < nb_of_ev) begin
            
            timeout = 16;
            while (timeout > 0 && !event_pending) begin
                @(negedge clk);
                timeout--;
            end

            if (event_pending) ack_event();
            
            counter++;
        end

    endtask // drop_events


    initial begin
        //--- Initial Values ---
        aer_ack_in = 1'b0;

        mode_in = 2'b00; // IDLE
        param_0_in = 8'h00;
        param_1_in = 8'h00;
        enable_in = 1'b0; // Disable

        errors = 0;
        event_count = 0;
        on_event = 0;
        off_event = 0;

        //--- Reset ---
        rst_n = 1'b0;
        repeat(10) @(negedge clk);
        rst_n = 1'b1;
        repeat(10) @(negedge clk);

        //--- Test 1 ---
        $display("====================================================================");
        $display("Test 1:   IDLE mode");
        $display("GOAL:     It must not genrate any events and no reqs are detected.");
        
        set_mode(2'b00, 8'h00, 8'h00);
        set_enable(1'b1);

        drop_events(16);

        set_enable(1'b0);

        $display("Results:");
        $display("      Events     : %d", event_count);
        $display("      ON events  : %d", on_event);
        $display("      OFF events : %d", off_event);

        if (event_count != 0) begin
            $display("ERROR:    The stimulus generator generates events when it is IDLE!!");
        end else begin
            $display("PASS:     Test 1 (IDLE mode) is done successfully.");
        end

        //--- Test 2 ---
        $display("====================================================================");
        // drop_events(16);
        reset_event_counters();

        $display("Test 2:   EDGE mode");
        $display("GOAL:     A vertical or horizontal edge is generated and we can see the pixel addresses alongside reqs.");

        set_mode(2'b01, 8'h4, 8'h01); // EDGE / perios : 4 / Dir: Horizontal
        set_enable(1'b1);

        drop_events(16);

        set_enable(1'b0);

        $display("Results:");
        $display("      Events     : %d", event_count);
        $display("      ON events  : %d", on_event);
        $display("      OFF events : %d", off_event);

        if (event_count == 0) begin
            $display("ERROR:    The stimulus generator does not generate any events!");
        end else if (errors) begin
            $display("ERROR:    There are %d errors", errors);
        end else if (on_event == 0) begin
            $display("WARNING:  No ON events are generated!");
        end else if (off_event == 0) begin
            $display("WARNING:  No OFF events are generated!");
        end else begin
            $display("PASS:     Test 2 (EDGE mode) is done successfully.");
        end

        //--- Test 3 ---
        $display("====================================================================");
        drop_events(20);
        reset_event_counters();

        $display("Test 3:   HOT mode");
        $display("GOAL:     A hot pixel is generated.");

        set_mode(2'b10, 8'h02, 8'h01); // HOT/ x : 2 / y : 1
        set_enable(1'b1);

        repeat(2 * ARRAY_SIZE_Y + 1 + 1 ) @(negedge clk); // x * ARRAY_SIZE_Y + y + 1

        drop_events(16);

        set_enable(1'b0);

        $display("Results:");
        $display("      Events     : %d", event_count);
        $display("      ON events  : %d", on_event);
        $display("      OFF events : %d", off_event);

        if (event_count == 0) begin
            $display("ERROR:    The stimulus generator does not generate any events!");
        end else if (errors) begin
            $display("ERROR:    There are %d errors", errors);
        end else if (on_event == 0) begin
            $display("WARNING:  No ON events are generated!");
        end else if (off_event == 0) begin
            $display("WARNING:  No OFF events are generated!");
        end else begin
            $display("PASS:     Test 3 (HOT mode) is done successfully.");
        end

        $display("====================================================================");
        #10

        $finish;
    end


    //--- Simulation Watchdog Timer ---
    initial begin
        #5_000_000
        $display("Warning: simulation timeout!");
        $finish;
    end


    initial begin
        $dumpfile("tb_event_generator.vcd");
        $dumpvars(0, tb_event_generator);
    end

endmodule
