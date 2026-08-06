module aer_pixel_array #(
    parameter ARRAY_SIZE_X = 16,
    parameter ARRAY_SIZE_Y = 16,
    parameter ADDR_WIDTH = 16
)(
    input logic clk,
    input logic rst_n,

    input logic [0 : ARRAY_SIZE_X * ARRAY_SIZE_Y - 1] stim_in,

    output logic aer_req_out,
    output logic [ADDR_WIDTH - 1 : 0] aer_addr_out,
    output logic aer_pol_out,
    input  logic aer_ack_in
);

    localparam PIXEL_COUNT = ARRAY_SIZE_X * ARRAY_SIZE_Y;

    logic [0 : PIXEL_COUNT - 1] pix_req;
    logic [ADDR_WIDTH - 1 : 0]  pix_addr [0 : PIXEL_COUNT - 1];
    logic [0 : PIXEL_COUNT - 1] pix_pol;
    logic [0 : PIXEL_COUNT - 1] pix_ack;

    
    genvar i, j;
    generate
        for (i = 0; i < ARRAY_SIZE_X; i++) begin : gen_pixel_row
            for (j = 0; j < ARRAY_SIZE_Y; j++) begin : gen_pixel_col
                aer_pixel #(
                    .PIXEL_X(i),
                    .PIXEL_Y(j),
                    .ADDR_WIDTH(ADDR_WIDTH)
                ) pixel_sensor (
                    .clk(clk),
                    .rst_n(rst_n),
                    .stimulus_in(stim_in[i * ARRAY_SIZE_X + j]),
                    .req_out(pix_req[i * ARRAY_SIZE_X + j]),
                    .pixel_addr_out(pix_addr[i * ARRAY_SIZE_X + j]),
                    .pol_out(pix_pol[i * ARRAY_SIZE_X + j]),
                    .ack_in(pix_ack[i * ARRAY_SIZE_X + j])
                );
            end
        end
    endgenerate


    aer_arbiter #(
        .ARRAY_SIZE_X(ARRAY_SIZE_X),
        .ARRAY_SIZE_Y(ARRAY_SIZE_Y),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) arbiter (
        .clk(clk),
        .rst_n(rst_n),

        //--- Upstream (pixels) ---
        .pix_req_in(pix_req),
        .pix_addr_in(pix_addr),
        .pix_pol_in(pix_pol),
        .pix_ack_out(pix_ack),

        //--- Downstream (Async FIFO) ---
        .aer_req_out(aer_req_out),
        .aer_addr_out(aer_addr_out),
        .aer_pol_out(aer_pol_out),
        .aer_ack_in(aer_ack_in)
    );


endmodule
