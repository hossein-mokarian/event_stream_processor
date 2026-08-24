module filter_v2 #(
    parameter HISTORY_DEPTH = 16,
    parameter ADDR_WIDTH = 16,
    parameter TIMESTAMP_WIDTH = 32,
    parameter FILTER_TIME_US = 50
)(
    //--- General ---
    input logic clk,
    input logic rst_n,

    //--- Events ---
    input logic ev_valid_in,
    input logic [ADDR_WIDTH - 1 : 0] ev_addr_in, // {x, y}
    input logic ev_pol_in,
    input logic [TIMESTAMP_WIDTH - 1 : 0] timestamp_in,

    //--- Filtered events ---
    output logic ev_valid_out,
    output logic [ADDR_WIDTH - 1 : 0] filtered_ev_addr_out,
    output logic filtered_ev_pol_out,
    output logic [TIMESTAMP_WIDTH - 1 : 0] timestamp_out,

    //--- Status ---
    output logic ev_pass_out,
    output logic ev_drop_out
);

    localparam EVENT_WIDTH = ADDR_WIDTH + 1 + TIMESTAMP_WIDTH;


    typedef struct packed {
        logic [ADDR_WIDTH / 2 - 1 : 0] x;
        logic [ADDR_WIDTH / 2 - 1 : 0] y;
        logic pol;
        logic [TIMESTAMP_WIDTH - 1 : 0] ts;
    } EVENT_t;

    typedef enum logic [2 : 0] { 
        IDLE,
        CAPTURE_EVT,
        COMPARE,
        FILTER,
        UPDATE
     } STATE_t;


    integer i;
    
    EVENT_t current_evt;

    STATE_t state;

    //--- History Module ---
    logic hist_wr_en;
    logic [EVENT_WIDTH - 1 : 0] hist_wr_data;
    logic hist_rd_en;
    logic [EVENT_WIDTH - 1 : 0] hist_rd_data;
    logic [$clog2(HISTORY_DEPTH) - 1 : 0] hist_addr;
    logic hist_rd_valid;
    logic [$clog2(HISTORY_DEPTH) - 1 : 0] hist_count;
    logic hist_empty;
    logic hist_full;

    //--- Comparesion ---
    logic [$clog2(HISTORY_DEPTH) - 1 : 0] comparision_idx;
    logic [$clog2(HISTORY_DEPTH) - 1 : 0] entries_to_check;
    logic correlation_found;

    logic [ADDR_WIDTH / 2 - 1 : 0] dx;
    logic [ADDR_WIDTH / 2 - 1 : 0] dy;
    logic [TIMESTAMP_WIDTH - 1 : 0] dts;
    EVENT_t hist_evt;


    //--- FSM ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE        : if (ev_valid_in) state <= CAPTURE_EVT;
                CAPTURE_EVT : state <= COMPARE;
                COMPARE     : if (comparision_idx >= entries_to_check || correlation_found) state <= FILTER;
                FILTER      : state <= UPDATE;
                UPDATE      : state <= IDLE;
                default     : state <= IDLE;
            endcase
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_evt <= '0;
        end else if (state == CAPTURE_EVT) begin
            current_evt <= {ev_addr_in, ev_pol_in, timestamp_in};
        end
    end

    
    assign hist_rd_en = (state == COMPARE);

    history_buffer #(
        .HISTORY_DEPTH(HISTORY_DEPTH),
        .EVENT_WIDTH(EVENT_WIDTH)
    ) hist_buff (
        //--- General ---
        .clk(clk),
        .rst_n(rst_n),

        //--- Write ---
        .wr_en_in(hist_wr_en),
        .wr_data_in(hist_wr_data),

        //--- Read ---
        .rd_en_in(hist_rd_en),
        .addr_in(hist_addr),
        .rd_data_out(hist_rd_data),
        .rd_valid_out(hist_rd_valid),

        //--- Status ---
        .count_out(hist_count),
        .empty_out(hist_empty),
        .full_out(hist_full)
    );

    assign hist_addr = comparision_idx;
    assign entries_to_check = hist_count;
    assign hist_evt = hist_rd_data;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comparision_idx <= '0;
            correlation_found <= 1'b0;
        end else if (state == CAPTURE_EVT) begin
            comparision_idx <= '0;
            correlation_found <= 1'b0;
        end else if (state == COMPARE) begin
            if (hist_rd_valid) begin
                dx  = (current_evt.x  > hist_evt.x ) ? (current_evt.x - hist_evt.x  ) : (hist_evt.x - current_evt.x);
                dy  = (current_evt.y  > hist_evt.y ) ? (current_evt.y - hist_evt.y  ) : (hist_evt.y - current_evt.y);
                dts = (current_evt.ts > hist_evt.ts) ? (current_evt.ts - hist_evt.ts) : ({TIMESTAMP_WIDTH{1'b1}} - hist_evt.ts + current_evt.ts);

                if (dx <= 1 && dy <= 1 && dts <= FILTER_TIME_US) begin
                    correlation_found <= 1'b1;
                end

                if (comparision_idx < entries_to_check || !correlation_found) begin
                    comparision_idx <= comparision_idx + 1'b1;
                end
            end
        end
    end

    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ev_valid_out <= 1'b0;
            filtered_ev_addr_out <= '0;
            filtered_ev_pol_out <= 1'b0;
            timestamp_out <= '0;
        end else if (state == FILTER && correlation_found) begin
            ev_valid_out <= 1'b1;
            filtered_ev_addr_out <= {current_evt.x, current_evt.y};
            filtered_ev_pol_out <= current_evt.pol;
            timestamp_out <= current_evt.ts;

            ev_pass_out <= 1'b1;
            ev_drop_out <= 1'b0;
        end else begin
            ev_valid_out <= 1'b0;
            ev_pass_out <= 1'b0;
            ev_drop_out <= 1'b1;
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hist_wr_en <= 1'b0;
            hist_wr_data <= '0;
        end else if (state == UPDATE) begin
            hist_wr_en <= 1'b1;
            hist_wr_data <= current_evt;
        end else begin
            hist_wr_en <= 1'b0;
        end
    end


endmodule
