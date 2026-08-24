module filter_subsystem #(
    parameter INPUT_CLK_FREQ_HZ = 50_000_000,
    parameter HISTORY_DEPTH = 16,
    parameter ADDR_WIDTH = 16,
    parameter TIMESTAMP_WIDTH = 32,
    parameter FILTER_TIME_US = 50
)(
    input logic clk,
    input logic rst_n,

    //--- Events ---
    input logic ev_valid_in,
    input logic [ADDR_WIDTH - 1 : 0] ev_addr_in, // {x, y}
    input logic ev_pol_in,
    // input logic [TIMESTAMP_WIDTH - 1 : 0] timestamp_in,

    //--- Filtered events ---
    output logic ev_valid_out,
    output logic [ADDR_WIDTH - 1 : 0] filtered_ev_addr_out,
    output logic filtered_ev_pol_out,
    output logic [TIMESTAMP_WIDTH - 1 : 0] timestamp_out,

    //--- Status ---
    output logic ev_pass_out,
    output logic ev_drop_out
);

    logic [TIMESTAMP_WIDTH - 1 : 0] timestamp;
    logic tick_1us;


    timestamp_counter #(
        .INPUT_CLK_FREQ_HZ(INPUT_CLK_FREQ_HZ)
    ) timer (
        .clk(clk),
        .rst_n(rst_n),

        .timestamp(timestamp),

        .tick_1us(tick_1us)
    );


    filter_v2 #(
        .HISTORY_DEPTH(HISTORY_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH),
        .FILTER_TIME_US(FILTER_TIME_US)
    ) filter (
        //--- General ---
        .clk(clk),
        .rst_n(rst_n),

        //--- Events ---
        .ev_valid_in(ev_valid_in),
        .ev_addr_in(ev_addr_in),
        .ev_pol_in(ev_pol_in),
        .timestamp_in(timestamp),

        //--- Filtered events ---
        .ev_valid_out(ev_valid_out),
        .filtered_ev_addr_out(filtered_ev_addr_out),
        .filtered_ev_pol_out(filtered_ev_pol_out),
        .timestamp_out(timestamp_out),

        //--- Status ---
        .ev_pass_out(ev_pass_out),
        .ev_drop_out(ev_drop_out)
    );

endmodule
