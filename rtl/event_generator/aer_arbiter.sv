module aer_arbiter #(
    parameter ARRAY_SIZE_X = 16,
    parameter ARRAY_SIZE_Y = 16,
    parameter ADDR_WIDTH   = 16
)(
    //--- General ---
    input  logic clk,
    input  logic rst_n,

    //--- Upstream (pixels) ---
    input  logic [0 : ARRAY_SIZE_X * ARRAY_SIZE_Y - 1] pix_req_in,
    input  logic [ADDR_WIDTH - 1                  : 0] pix_addr_in [0 : ARRAY_SIZE_X * ARRAY_SIZE_Y - 1],
    input  logic [0 : ARRAY_SIZE_X * ARRAY_SIZE_Y - 1] pix_pol_in,
    output logic [0 : ARRAY_SIZE_X * ARRAY_SIZE_Y - 1] pix_ack_out,

    //--- Downstream (Async FIFO) ---
    output logic aer_req_out,
    output logic [ADDR_WIDTH - 1 : 0] aer_addr_out,
    output logic aer_pol_out,
    input  logic aer_ack_in
);

    localparam PIXEL_COUNT = ARRAY_SIZE_X * ARRAY_SIZE_Y;
    localparam IDX_WIDTH = $clog2(PIXEL_COUNT);


    typedef enum logic [1 : 0] { 
        IDLE,
        DOWNSTREAM_REQ,
        DOWNSTREAM_ACK,
        WAIT_FOR_LOW
    } STATE_t;

    
    integer i;

    STATE_t state;
    logic [0 : PIXEL_COUNT - 1] sampled_req;
    logic [0 : PIXEL_COUNT - 1] next_pix_ack;
    logic [IDX_WIDTH - 1 : 0] pix_idx;


    //--- Finite State Machine (FSM) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE           : if (pix_req_in) state <= DOWNSTREAM_REQ;
                DOWNSTREAM_REQ : state <= DOWNSTREAM_ACK;
                DOWNSTREAM_ACK : if (aer_ack_in) state <= WAIT_FOR_LOW;
                WAIT_FOR_LOW   : if (!aer_ack_in && !pix_req_in[pix_idx]) state <= IDLE;
                default        : state <= IDLE;
            endcase
        end
    end


    //--- Get sample from pixel request ---
    always_comb begin
        if (!rst_n) begin
            sampled_req = {PIXEL_COUNT{1'b0}};
        end else if (state == IDLE && pix_req_in) begin
            sampled_req = pix_req_in;
        end else begin
            sampled_req = sampled_req;
        end
    end

    
    //--- Use Round-Robin arbiter to get grant ---
    rr_arbiter #(
        .REQ_COUNT(PIXEL_COUNT)
    ) round_robin_arbiter (
        .clk(clk & (state == IDLE)),
        .rst_n(rst_n),
        .en((state == IDLE)),

        .req_in(sampled_req),
        .grant_out(next_pix_ack)
    );


    //--- pixel index ---
    always_comb begin
        pix_idx = '0;

        for (i = 0; i < PIXEL_COUNT; i = i + 1) begin
            if (next_pix_ack[i]) begin
                pix_idx = pix_idx | {IDX_WIDTH'(i)};
            end
        end
    end


    //--- Downstream Request ---
    assign aer_req_out = (state == DOWNSTREAM_REQ || state == DOWNSTREAM_ACK) ? 1'b1 : 1'b0;


    //--- Pixel address and polarity ---
    assign aer_addr_out = pix_addr_in[pix_idx];
    assign aer_pol_out  = pix_pol_in [pix_idx];


    //--- Set pixel ack (Upstream ACK) ---
    assign pix_ack_out = (state == WAIT_FOR_LOW) ? next_pix_ack : 'b0;


endmodule
