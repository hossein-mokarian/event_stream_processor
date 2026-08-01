module aer_pixel #(
    parameter PIXEL_X = 0,
    parameter PIXEL_Y = 0,
    parameter ADDR_WIDTH = 16
)(
    input logic clk,
    input logic rst_n,

    input logic stimulus,

    output logic req,
    output logic [ADDR_WIDTH - 1 : 0] pixel_addr,
    output logic pol,
    input logic ack
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
        end else if (state == IDLE && stimulus) begin
            last_stimulus <= stimulus;
            stimulus_posedge <= (!last_stimulus && stimulus);
            stimulus_negedge <= (last_stimulus && !stimulus);
        end
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: if (stimulus) state <= REQUEST;
                REQUEST: if (ack) state <= WAIT_FOR_LOW_ACK;
                WAIT_FOR_LOW_ACK: if (!ack) state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            event_pol <= 1'b0;
        end else if (state == IDLE) begin
            if (stimulus_posedge)
                event_pol <= 1'b1;
            else if (stimulus_negedge)
                event_pol <= 1'b0;
        end
    end


    assign req = (state == REQUEST);
    assign pixel_addr = {PIXEL_X[7 : 0], PIXEL_Y[7 : 0]};
    assign pol = event_pol;


endmodule
