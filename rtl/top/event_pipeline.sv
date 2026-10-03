module event_pipeline #(
    //--- Event generator ---
    parameter ARRAY_SIZE_X = 16,
    parameter ARRAY_SIZE_Y = 16,
    parameter ADDR_WIDTH   = 16,

    //--- CDC ---
    parameter DATA_WIDTH      = 32,
    parameter FIFO_ADDR_WIDTH = 4,

    //--- Filter ---
    parameter INPUT_CLK_FREQ_HZ = 50_000_000,
    parameter HISTORY_DEPTH     = 16,
    // parameter ADDR_WIDTH        = 16,
    parameter TIMESTAMP_WIDTH   = 32,
    parameter FILTER_TIME_US    = 50
)(
    //--- Genearl ---
    input logic pix_clk,
    input logic pix_rst_n,

    input logic sys_clk,
    input logic sys_rst_n,

    //--- Event generator ---
    input logic [1 : 0] mode_in,
    input logic [7 : 0] param_0_in,
    input logic [7 : 0] param_1_in,
    input logic enable_in,

    output logic event_pending_out,

    //--- CDC ---

    //--- Filter ---
    output logic ev_valid_out,
    output logic [ADDR_WIDTH - 1 : 0] filtered_ev_addr_out,
    output logic filtered_ev_pol_out,
    output logic [TIMESTAMP_WIDTH - 1 : 0] timestamp_out,

    output logic ev_pass_out,
    output logic ev_drop_out
);

    //--- Event generator ---
    logic aer_req;
    logic [ADDR_WIDTH - 1 : 0] aer_addr;
    logic aer_pol;
    logic aer_ack;

    //--- CDC ---
    logic sys_aer_req;
    logic [DATA_WIDTH - 1 : 0] cdc_rdata;
    logic sys_aer_ack;

    //--- Filter ---
    logic ev_valid;


    event_generator_top #(
        .ARRAY_SIZE_X(ARRAY_SIZE_X),
        .ARRAY_SIZE_Y(ARRAY_SIZE_Y),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ev_gen (
        .clk(pix_clk),
        .rst_n(pix_rst_n),

        //--- Stim generator ---
        .mode_in(mode_in),
        .param_0_in(param_0_in),
        .param_1_in(param_1_in),
        .enable_in(enable_in),

        //--- AER ---
        .aer_req_out(aer_req),
        .aer_addr_out(aer_addr),
        .aer_pol_out(aer_pol),
        .aer_ack_in(aer_ack),

        //--- Status ---
        .event_pending_out(event_pending_out)
    );


    event_cdc_bridge #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) cdc_bridge (
        //--- Write Domain ---
        .wclk_in(pix_clk),
        .wrst_n(pix_rst_n),

        //--- Read Domain ---
        .rclk_in(sys_clk),
        .rrst_n(sys_rst_n),

        //--- AER ---
        .pix_aer_req_in(aer_req),
        .pix_aer_data_in({{(DATA_WIDTH - (ADDR_WIDTH + 1)){1'b0}}, aer_addr, aer_pol}), // {aer_addr, aer_pol}
        .pix_aer_ack_out(aer_ack),

        //--- Downstream ---
        .sys_aer_req_out(sys_aer_req),
        .sys_aer_data_out(cdc_rdata),
        .sys_aer_ack_in(sys_aer_ack)
    );


    filter_subsystem #(
        .INPUT_CLK_FREQ_HZ(INPUT_CLK_FREQ_HZ),
        .HISTORY_DEPTH(HISTORY_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH),
        .FILTER_TIME_US(FILTER_TIME_US)
    ) filter (
        .clk(sys_clk),
        .rst_n(sys_rst_n),

        //--- Events ---
        .ev_valid_in(sys_aer_req),
        .ev_addr_in(cdc_rdata[DATA_WIDTH - 1 : 1]),
        .ev_pol_in(cdc_rdata[0]),
        // .timestamp_in(),
        .ev_ack_out(sys_aer_ack),

        //--- Filtered events ---
        .ev_valid_out(ev_valid_out),
        .filtered_ev_addr_out(filtered_ev_addr_out),
        .filtered_ev_pol_out(filtered_ev_pol_out),
        .timestamp_out(timestamp_out),

        //--- Status ---
        .ev_pass_out(ev_pass_out),
        .ev_drop_out(ev_drop_out)
    );

    // assign sys_aer_ack = (sys_rst_n) ? 1'b1 : 1'b0;


endmodule
