`timescale 1ns/1ps


module tb_cdc_integration;

    //--- AER ---
    localparam ARRAY_SIZE_X = 4;
    localparam ARRAY_SIZE_Y = 4;
    localparam AER_ADDR_WIDTH = 16;
    localparam DATA_WIDTH = AER_ADDR_WIDTH + 2; // addr width + pol width

    //--- FIFO ---
    localparam FIFO_DATA_WIDTH = DATA_WIDTH;
    localparam FIFO_ADDR_WIDTH = 4;

    //--- CLK ---
    localparam PIX_CLK_FREQ_HZ = 50_000_000;
    localparam PIX_CLK_PERIOD = 1_000_000_000 / PIX_CLK_FREQ_HZ;

    localparam SYS_CLK_FREQ_HZ = 100_000_000;
    localparam SYS_CLK_PERIOD = 1_000_000_000 / SYS_CLK_FREQ_HZ;


    //--- CLKs & Reset ---
    logic pix_clk;
    logic sys_clk;
    logic pix_rst_n;
    logic sys_rst_n;

    //--- Stim generator ---
    logic [1 : 0] mode;
    logic [7 : 0] param_0;
    logic [7 : 0] param_1;
    logic enable;

    //--- AER ---
    logic aer_req;
    logic [AER_ADDR_WIDTH - 1 : 0] aer_addr;
    logic aer_pol;
    logic aer_ack;

    //--- Status ---
    logic event_pending;

    //--- Write Domain ---
    // logic wclk;
    // logic wrst_n;

    //--- Read Domain ---
    // logic rclk;
    // logic rrst_n;

    //--- AER ---
    logic sys_ren;
    logic [DATA_WIDTH - 1 : 0] aer_data;
    // logic aer_ack;

    //--- Downstream ---
    logic ren_in;
    logic [FIFO_DATA_WIDTH - 1 : 0] rdata;
    logic rvalid;

    //--- Verfication ---
    integer errors;
    integer events;
    integer on_event;
    integer off_event;

    typedef struct {
        logic [7 : 0] x;
        logic [7 : 0] y;
        logic pol;
    } EVENT_t;

    EVENT_t event_queue [$];


    event_generator_top #(
        .ARRAY_SIZE_X(ARRAY_SIZE_X),
        .ARRAY_SIZE_Y(ARRAY_SIZE_Y),
        .ADDR_WIDTH(AER_ADDR_WIDTH)
    ) ev_gen (
        .clk(pix_clk),
        .rst_n(pix_rst_n),

        //--- Stim generator ---
        .mode_in(mode),
        .param_0_in(param_0),
        .param_1_in(param_1),
        .enable_in(enable),

        //--- AER ---
        .aer_req_out(aer_req),
        .aer_addr_out(aer_addr),
        .aer_pol_out(aer_pol),
        .aer_ack_in(aer_ack),

        //--- Status ---
        .event_pending_out(event_pending)
    );


    assign aer_data = {aer_addr, aer_pol};


    event_cd_bridge #(
        .DATA_WIDTH(FIFO_DATA_WIDTH),
        .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) ev_bridge (
        //--- Write Domain ---
        .wclk_in(pix_clk),
        .wrst_n(pix_rst_n),

        //--- Read Domain ---
        .rclk_in(sys_clk),
        .rrst_n(sys_rst_n),

        //--- AER ---
        .aer_req_in(aer_req),
        .aer_data_in(aer_data),
        .aer_ack_out(aer_ack),

        //--- Downstream ---
        .sys_ren_in(sys_ren),
        .rdata_out(rdata),
        .rvalid_out(rvalid)
    );


    //--- Generate CLK ---
    initial pix_clk = 0;
    always #(PIX_CLK_PERIOD / 2) pix_clk = ~pix_clk;

    initial sys_clk = 0;
    always #(SYS_CLK_PERIOD / 2) sys_clk = ~sys_clk;


    //--- Functuions ---
    function reset_event_counters();
        events = 0;
        on_event = 0;
        off_event = 0;
    endfunction


    //--- Tasks ---
    task automatic set_mode (
        input logic [1 : 0] m,
        input logic [7 : 0] p1,
        input logic [7 : 0] p2
    );
        mode = m;
        param_0 = p1;
        param_1 = p2;
    endtask // set_mode

    task automatic set_enable(input logic en);
        enable = en;
        repeat(2) @(posedge pix_clk);
    endtask // set_enable

    task automatic delay (input logic [31 : 0] d);
        repeat(d) @(posedge pix_clk);
    endtask // delay


    //--- Main Test ---
    initial begin

        //--- Initalial Values ---
        mode    = 2'b00; // IDLE Mode
        param_0 = 8'h00;
        param_1 = 8'h00;
        enable  = 1'b0;

        sys_ren = 1'b0;

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
        $display("====================================================================");
        $display("Test 1 :      ");
        $display("GOAL   :      ");

        reset_event_counters();
        set_mode(2'b01, 8'h04, 8'h01); // mode=EDGE, speed=8'h04, edge_direction=8'h01
        set_enable(1'b1);
        delay(100);
        set_enable(1'b0);

        $display("Results   : ");
        $display("events    :     %d", events   );
        $display("on_event  :     %d", on_event );
        $display("off_event :     %d", off_event);

        if (errors) begin
            $display("ERROR: There are many errors!");
        end else if (!on_event) begin
            $display("WARNING: No on_events are generated!");
        end else if (!off_event) begin
            $display("WARNING: No off_events are generated!");
        end else begin
            $display("PASS: Simulation is done successfully.");
        end

        //--- Test 2 ---
        $display("====================================================================");


        #100

        $finish;

    end


    //--- Simultion Timeout Watchdog ---
    initial begin
        #5_000_000
        $display("WARNING: Simulation Timeout!");
        $finish;
    end


    //--- Save results ---
    initial begin
        $dumpfile("tb_cdc_integration.vcd");
        $dumpvars(0, tb_cdc_integration);
    end

    
endmodule
