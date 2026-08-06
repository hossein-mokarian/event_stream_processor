module aer_pixel #(
    parameter PIXEL_X = 0,
    parameter PIXEL_Y = 0,
    parameter ADDR_WIDTH = 16
)(
    input logic clk,
    input logic rst_n,

    input logic stimulus_in,

    output logic req_out,
    output logic [ADDR_WIDTH - 1 : 0] pixel_addr_out,
    output logic pol_out,
    input logic ack_in
);

    typedef enum logic [1 : 0] { 
        IDLE,
        REQUEST,
        WAIT_FOR_LOW_ACK
     } STATE_t;


    logic last_stimulus;

    logic stimulus_posedge;
    logic stimulus_negedge;

    logic event_pol;

    STATE_t state;


    always_ff @(posedge clk or rst_n) begin
        if (!rst_n) begin
            last_stimulus <= 1'b0;
            stimulus_posedge <= 1'b0;
            stimulus_negedge <= 1'b0;
        end else if (state == IDLE && stimulus_in) begin
            last_stimulus <= stimulus_in;
            stimulus_posedge <= (!last_stimulus && stimulus_in);
            stimulus_negedge <= (last_stimulus && !stimulus_in);
        end
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: if (stimulus_in) state <= REQUEST;
                REQUEST: if (ack_in) state <= WAIT_FOR_LOW_ACK;
                WAIT_FOR_LOW_ACK: if (!ack_in) state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end


    always_comb begin
        if (!rst_n) begin
            event_pol <= 1'b0;
        end else if(stimulus_posedge)  begin
            event_pol <= 1'b1;
        end else if (stimulus_negedge) begin
            event_pol <= 1'b0;
        end
    end


    assign req_out = (state == REQUEST) ? 1'b1 : 1'b0;
    assign pixel_addr_out = {PIXEL_X[7 : 0], PIXEL_Y[7 : 0]};
    assign pol_out = event_pol;


endmodule
