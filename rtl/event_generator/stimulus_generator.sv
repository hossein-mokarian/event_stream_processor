module stimulus_generator #(
    parameter ARRAY_SIZE_X = 16,
    parameter ARRAY_SIZE_Y = 16,
    parameter ADDR_WIDTH = 16
)(
    input logic clk,
    input logic rst_n,

    input logic [1 : 0] mode_in,
    input logic [7 : 0] param_0_in,
    input logic [7 : 0] param_1_in,
    input logic enable_in,

    output logic [0 : ARRAY_SIZE_X * ARRAY_SIZE_Y - 1] stim_out
);

    localparam PIXEL_COUNT = ARRAY_SIZE_X * ARRAY_SIZE_Y;


    typedef enum logic [1 : 0] { 
        IDLE,
        EDGE,
        HOT,
        NOISE
    } MODE_t;


    integer i;
    
    MODE_t mode;
    MODE_t last_mode;
    logic mode_changed;

    //--- Timer ---
    logic [$clog2(ARRAY_SIZE_Y) - 1 : 0] timer_counter;
    logic timer_tick;
    logic [7 : 0] timer_period;

    //--- EDGE ---
    logic [$clog2(ARRAY_SIZE_Y) - 1 : 0] edge_pos;
    logic edge_dir;
    logic [$clog2(ARRAY_SIZE_X) - 1 : 0] edge_pos_max;

    //--- HOT ---
    logic [$clog2(ARRAY_SIZE_X) - 1 : 0] hot_x;
    logic [$clog2(ARRAY_SIZE_Y) - 1 : 0] hot_y;
    logic hot_toggle;

    //--- NOISE ---

    //--- Stimulus ---
    logic [0 : PIXEL_COUNT - 1] stim;


    //--- Mode ---
    assign mode = MODE_t'(mode_in);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_mode <= IDLE;
        end else if (enable_in) begin
            last_mode <= mode;
        end
    end

    assign mode_changed = (last_mode != mode) ? 1'b1 : 1'b0;


    //--- Timer period ---
    always_comb begin
        if (!rst_n) begin
            timer_period = '0;
        end else if (mode == EDGE) begin
            timer_period = param_0_in;
        end
    end


    //--- Timer ---
    always_ff @(posedge clk or negedge rst_n ) begin
        if (!rst_n) begin
            timer_counter <= '0;
            timer_tick <= 1'b0;
        end else if (mode_changed || !enable_in) begin
            timer_counter <= '0;
            timer_tick <= 1'b0;
        end else if ((mode != IDLE) && enable_in) begin
            if (timer_counter >= (timer_period - 1)) begin
                timer_counter <= '0;
                timer_tick <= 1'b1;
            end else begin
                timer_counter <= timer_counter + 1;
                timer_tick <= 1'b0;
            end
        end
        else begin
            timer_counter <= '0;
            timer_tick <= 1'b0;
        end
    end


    //--- Mode : EDGE ---
    assign edge_dir = (mode == EDGE) ? param_1_in : 1'b0;
    assign edge_pos_max = edge_dir ? ARRAY_SIZE_Y - 1 : ARRAY_SIZE_X - 1; // Todo: bit-width of edge_pos_max??

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_pos <= 0;
        end else if (mode == EDGE && enable_in) begin
            if (timer_tick) begin
                if (edge_pos >= edge_pos_max) begin
                    edge_pos <= 0;
                end else begin
                    edge_pos <= edge_pos + 1;
                end
            end
        end else begin
            edge_pos <= 0;
        end
    end


    //--- Mode : HOT ---
    assign hot_x = (mode == HOT) ? param_0_in : '0;
    assign hot_y = (mode == HOT) ? param_1_in : '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hot_toggle <= 1'b1;
        end else if (mode == HOT && enable_in) begin
            if (timer_tick) begin
                hot_toggle <= ~hot_toggle;
            end
        end else begin
            hot_toggle <= 1'b0;
        end
    end


    //--- Mode : NOISE ---


    //--- Genearte stim ---
    always_comb begin
        if (!rst_n) begin
            stim = {PIXEL_COUNT{1'b0}};
        end else if (!enable_in) begin
            stim = {PIXEL_COUNT{1'b0}};
        end else if (mode == EDGE) begin
            stim = {PIXEL_COUNT{1'b0}};
            if (edge_dir) begin // Horizontal edge
                for (i = 0 ; i < ARRAY_SIZE_Y; i = i + 1) begin
                    stim[edge_pos * ARRAY_SIZE_X + i] = 1'b1;
                end
            end else begin // Vertical edge
                for (i = 0 ; i < ARRAY_SIZE_Y; i = i + 1) begin
                    stim[i * ARRAY_SIZE_X + edge_pos] = 1'b1;
                end
            end
        end else if (mode == HOT) begin
            stim = {PIXEL_COUNT{1'b0}};
            stim[hot_x * ARRAY_SIZE_X + hot_y] = hot_toggle;
        end else if (mode == NOISE) begin
            stim = {PIXEL_COUNT{1'b0}};
            // noise
        end else begin
            stim = {PIXEL_COUNT{1'b0}};
        end
    end

    assign stim_out = stim;


endmodule
