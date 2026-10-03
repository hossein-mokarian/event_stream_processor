`define DEBUG_MODE


module spatiotemporal_filter #(
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
    output logic ev_ack_out,

    //--- Filtered events ---
    output logic ev_valid_out,
    output logic [ADDR_WIDTH - 1 : 0] filtered_ev_addr_out,
    output logic filtered_ev_pol_out,
    output logic [TIMESTAMP_WIDTH - 1 : 0] timestamp_out,

    //--- Status ---
    output logic ev_pass_out,
    output logic ev_drop_out
);

    //--- Params ---
    localparam STEP_COUNT = 3;


    //--- Typedefs ---
    typedef enum logic [1 : 0] { 
        S1_SAMPLE,
        S2_FILTER,
        S3_UPDATE
    } STEP_t;

    typedef struct packed {
        logic [ADDR_WIDTH / 2 - 1 : 0] x;
        logic [ADDR_WIDTH / 2 - 1 : 0] y;
        logic pol;
        logic [TIMESTAMP_WIDTH - 1 : 0] ts;
    } EVENT_t;


    integer i, j, k, m;

    EVENT_t event_history [0 : HISTORY_DEPTH - 1];
    logic [$clog2(HISTORY_DEPTH) - 1 : 0] wptr;
    logic history_full;
    logic [$clog2(HISTORY_DEPTH) - 1 : 0] history_size;

    //--- Pipeline regs ---
    logic [0 : STEP_COUNT - 1] ev_valid;
    logic [ADDR_WIDTH - 1 : 0] ev_addr [0 : STEP_COUNT - 1];
    logic [0 : STEP_COUNT - 1] ev_pol;
    logic [TIMESTAMP_WIDTH - 1 : 0] ev_ts [0 : STEP_COUNT - 1];

    //--- Current values ---
    logic [ADDR_WIDTH / 2 - 1  : 0] x;
    logic [ADDR_WIDTH / 2 - 1  : 0] y;
    logic [TIMESTAMP_WIDTH - 1 : 0] ts;
    
    //--- Diff ---
    logic [ADDR_WIDTH / 2 - 1 : 0] dx [0 : HISTORY_DEPTH - 1];
    logic [ADDR_WIDTH / 2 - 1 : 0] dy [0 : HISTORY_DEPTH - 1];
    logic [TIMESTAMP_WIDTH - 1 : 0] dts [0 : HISTORY_DEPTH - 1];

    //--- Result ---
    logic [0 : HISTORY_DEPTH - 1] is_event;
    logic event_found;

    
    //--- Pipeline registers ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < STEP_COUNT; i = i + 1) begin
                ev_valid[i] <= 1'b0;
                ev_addr [i] <= {ADDR_WIDTH{1'b0}};
                ev_pol  [i] <= 1'b0;
                ev_ts   [i] <= {TIMESTAMP_WIDTH{1'b0}};
            end
        end else begin
            ev_valid[0] <= ev_valid_in && ev_ack_out;
            
            if (ev_valid_in) begin
                ev_addr[0] <= ev_addr_in;
                ev_pol [0] <= ev_pol_in;
                ev_ts  [0] <= timestamp_in;
            end

            for (i = 0; i < STEP_COUNT - 1; i = i + 1) begin
                ev_valid[i + 1] <= ev_valid[i];
                ev_addr [i + 1] <= ev_addr [i];
                ev_pol  [i + 1] <= ev_pol  [i];
                ev_ts   [i + 1] <= ev_ts   [i];
            end
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ev_ack_out <= 1'b0;
        end else if (ev_valid_in) begin
            ev_ack_out <= 1'b1;
        end else begin
            ev_ack_out <= 1'b0;
        end
    end


    //--- Step 2 : FILTER ---
    assign x = ev_addr[S2_FILTER][ADDR_WIDTH - 1     : ADDR_WIDTH / 2];
    assign y = ev_addr[S2_FILTER][ADDR_WIDTH / 2 - 1 : 0             ];
    assign ts = ev_ts [S2_FILTER];

    //--- Calculate differences ---
    always_comb begin
        if (!rst_n) begin
            for (j = 0; j < HISTORY_DEPTH; j = j + 1) begin
                dx[j]  = 0;
                dy[j]  = 0;
                dts[j] = 0;
            end

            is_event = {HISTORY_DEPTH{1'b0}};
            history_size = '0;

        end else if (ev_valid[S2_FILTER]) begin
            is_event = {HISTORY_DEPTH{1'b0}};

            // history_size = history_full ? HISTORY_DEPTH : (wptr == '0 ? 1'b0 : wptr);
            if (history_full) begin
                history_size = HISTORY_DEPTH;
            end else begin
                if (wptr == 0) begin
                    history_size = 'h01;
                end else begin
                    history_size = wptr;
                end
            end

            for (j = 0; j < history_size; j = j + 1) begin
                dx[j]  = (x  >= event_history[j].x)  ? x - event_history[j].x   : event_history[j].x - x;
                dy[j]  = (y  >= event_history[j].y)  ? y - event_history[j].y   : event_history[j].y - y;
                dts[j] = (ts >= event_history[j].ts) ? ts - event_history[j].ts : ({TIMESTAMP_WIDTH{1'b1}} - event_history[j].ts + ts);

                if (dx[j] <= 1 && dy[j] <= 1 && dts[j] <= FILTER_TIME_US) begin
                    is_event[j] = 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            event_found <= 1'b0;
        end else if (ev_valid[S2_FILTER] && |is_event) begin
            event_found <= 1'b1;
        end else begin
            event_found <= 1'b0;
        end
    end


    //--- Step 3 : update history ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (m = 0; m < HISTORY_DEPTH; m = m + 1) begin
                event_history[m] <= {{ADDR_WIDTH{1'b0}}, 1'b0, {TIMESTAMP_WIDTH{1'b0}}};
            end
        end else if (ev_valid[S3_UPDATE] && event_found) begin
            event_history[wptr].x   <= ev_addr[S3_UPDATE][ADDR_WIDTH - 1     : ADDR_WIDTH / 2];
            event_history[wptr].y   <= ev_addr[S3_UPDATE][ADDR_WIDTH / 2 - 1 : 0             ];
            event_history[wptr].pol <= ev_pol [S3_UPDATE];
            event_history[wptr].ts  <= ev_ts  [S3_UPDATE];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= '0;
            history_full <= 1'b0;
        end else if (ev_valid[S3_UPDATE] && event_found) begin
            if (wptr >= HISTORY_DEPTH - 1) begin
                wptr <= '0;
                history_full <= 1'b1;
            end else begin
                wptr <= wptr + 1;
            end
        end
    end

    
    //--- Set output data ---
    assign ev_valid_out         = ev_valid[S3_UPDATE] && event_found;
    assign filtered_ev_addr_out = ev_addr [S3_UPDATE];
    assign filtered_ev_pol_out  = ev_pol  [S3_UPDATE];
    assign timestamp_out        = ev_ts   [S3_UPDATE];


    //--- Set debug signals ---
    assign ev_pass_out = (!rst_n) ? 1'b0 : ev_valid_out;
    assign ev_drop_out = (!rst_n) ? 1'b0 : ~ev_valid_out;
    

    //--- Debug ---
    `ifdef DEBUG_MODE
        genvar gi;

        generate
            for (gi = 0; gi < STEP_COUNT; gi++) begin : gen_ev_step
                wire [ADDR_WIDTH - 1 : 0] addr = ev_addr[gi];
                wire [TIMESTAMP_WIDTH - 1 : 0] ts = ev_ts[gi];
            end
        endgenerate

        generate
            for (gi = 0; gi < HISTORY_DEPTH; gi++) begin : gen_diff
                wire [ADDR_WIDTH / 2 - 1 : 0] dbg_dx = dx[gi];
                wire [ADDR_WIDTH / 2 - 1 : 0] dbg_dy = dy[gi];
                wire [TIMESTAMP_WIDTH - 1 : 0] dbg_dts = dts[gi];
            end
        endgenerate

        generate
            for (gi = 0; gi < HISTORY_DEPTH; gi++) begin : gen_ev_hist
                wire [ADDR_WIDTH / 2 - 1 : 0] dbg_x = event_history[gi].x;
                wire [ADDR_WIDTH / 2 - 1 : 0] dbg_y = event_history[gi].y;
                wire dbg_pol = event_history[gi].pol;
                wire [TIMESTAMP_WIDTH - 1 : 0] dbg_ts = event_history[gi].ts;
            end
        endgenerate
    `endif


endmodule
