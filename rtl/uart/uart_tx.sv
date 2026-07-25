module uart_tx #(
    parameter INPUT_CLK_FREQ_HZ = 50_000_000,
    parameter BAUD_RATE = 10400,
    parameter UART_DATA_WIDTH = 8
)(
    // General
    input logic clk,
    input logic rst_n,

    // Inputs
    input logic [7:0] data_in,
    input logic data_valid_in,

    // outputs
    output logic tx_out,
    output logic busy_out
);

    localparam BIT_PERIOD = INPUT_CLK_FREQ_HZ/BAUD_RATE;
    localparam BIT_CNT_WIDTH = $clog2(BIT_PERIOD);
    
    localparam BIT_INDEX_WIDTH = $clog2(UART_DATA_WIDTH);

    typedef enum logic [1 : 0] { 
        IDLE,
        START_BIT,
        DATA,
        STOP_BIT
    } UART_TX_STATE_t;


    UART_TX_STATE_t state;
    logic tx_active;
    logic [UART_DATA_WIDTH + 2 - 1 : 0] data;
    logic [BIT_INDEX_WIDTH - 1 : 0] bit_index;

    logic [BIT_CNT_WIDTH - 1 : 0] bit_timer_cnt;
    logic bit_timer_done;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_timer_cnt <= '0;
            bit_timer_done <= 1'b0;
        end else if (!tx_active) begin
            bit_timer_cnt <= 0;
            bit_timer_done <= 0;
        end else if (bit_timer_cnt == BIT_PERIOD - 1) begin
            bit_timer_cnt <= 0;
            bit_timer_done <= 1'b1;
        end else begin
            bit_timer_cnt <= bit_timer_cnt + 1;
            bit_timer_done <= 1'b0;
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_active <= 1'b0;
        end else begin
            case (state)
                IDLE:
                    if (data_valid_in) begin
                        state <= START_BIT;
                        tx_active <= 1'b1;
                    end else begin
                        tx_active <= 1'b0;
                    end
                START_BIT:
                    if (bit_timer_done)
                        state <= DATA;
                DATA:
                    if (bit_timer_done && bit_index == UART_DATA_WIDTH - 1)
                        state <= STOP_BIT;
                STOP_BIT:
                    if (bit_timer_done) begin
                        state <= IDLE;
                        tx_active <= 1'b0;
                    end
                default: state <= IDLE;
            endcase
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_index <= 0;
        end else if (state == DATA && bit_timer_done) begin
            if (bit_index == UART_DATA_WIDTH - 1) begin
                bit_index <= 0;
            end else begin
                bit_index <= bit_index + 1;
            end
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= {{UART_DATA_WIDTH + 2}{1'b1}};
        end else if (state == IDLE && data_valid_in) begin
            data = {1'b1, data_in, 1'b0};
        end else if (state != IDLE && bit_timer_done) begin
            data <= data >> 1;
        end
    end


    assign tx_out = (state == IDLE) ? 1'b1 : data[0];
    assign busy_out = tx_active || data_valid_in;


endmodule
