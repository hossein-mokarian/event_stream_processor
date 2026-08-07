module event_generator_top #(
    parameter ARRAY_SIZE_X = 16,
    parameter ARRAY_SIZE_Y = 16,
    parameter ADDR_WIDTH = 16
)(
    input logic clk,
    input logic rst_n,

    //--- Stim generator ---
    input logic [1 : 0] mode_in,
    input logic [7 : 0] param_0_in,
    input logic [7 : 0] param_1_in,
    input logic enable_in,

    //--- AER ---
    output logic aer_req_out,
    output logic [ADDR_WIDTH - 1 : 0] aer_addr_out,
    output logic aer_pol_out,
    input  logic aer_ack_in,

    //--- Status ---
    output logic event_pending_out
);

    logic [0 : ARRAY_SIZE_X * ARRAY_SIZE_Y - 1] stim;
    

    stimulus_generator #(
        .ARRAY_SIZE_X(ARRAY_SIZE_X),
        .ARRAY_SIZE_Y(ARRAY_SIZE_Y),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) stim_gen (
        .clk(clk),
        .rst_n(rst_n),

        .mode_in(mode_in),
        .param_0_in(param_0_in),
        .param_1_in(param_1_in),
        .enable_in(enable_in),

        .stim_out(stim)
    );


    aer_pixel_array #(
        .ARRAY_SIZE_X(ARRAY_SIZE_X),
        .ARRAY_SIZE_Y(ARRAY_SIZE_Y),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) aer_pixel_array (
        .clk(clk),
        .rst_n(rst_n),

        .stim_in(stim),

        .aer_req_out(aer_req_out),
        .aer_addr_out(aer_addr_out),
        .aer_pol_out(aer_pol_out),
        .aer_ack_in(aer_ack_in)
    );


    assign event_pending_out = aer_req_out;


endmodule
