module history_buffer #(
    parameter HISTORY_DEPTH = 64,
    parameter EVENT_WIDTH = 49
)(
    //--- General ---
    input logic clk,
    input logic rst_n,

    //--- Write ---
    input logic wr_en_in,
    input logic [EVENT_WIDTH - 1 : 0] wr_data_in,

    //--- Read ---
    input logic rd_en_in,
    input logic [$clog2(HISTORY_DEPTH) - 1 : 0] addr_in,
    output logic [EVENT_WIDTH - 1 : 0] rd_data_out,
    output logic rd_valid_out,

    //--- Status ---
    output logic [$clog2(HISTORY_DEPTH) - 1 : 0] count_out,
    output logic empty_out,
    output logic full_out
);

    integer i;

    logic [EVENT_WIDTH - 1 : 0] evt_hist_bram [0 : HISTORY_DEPTH - 1];
    logic [$clog2(HISTORY_DEPTH) - 1 : 0] wr_ptr;
    logic [$clog2(HISTORY_DEPTH) - 1 : 0] data_count;


    //--- Write ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en_in) begin
            if (wr_ptr == HISTORY_DEPTH - 1) begin
                wr_ptr <= '0;
            end else begin
                wr_ptr <= wr_ptr + 1;
            end
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_count <= '0;
        end else if (wr_en_in && data_count < HISTORY_DEPTH) begin
            data_count <= data_count + 1;
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < HISTORY_DEPTH; i = i + 1) begin
                evt_hist_bram[i] <= 0;
            end
        end else if (wr_en_in) begin
            evt_hist_bram[wr_ptr] <= wr_data_in;
        end
    end


    //--- Read ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data_out <= 0;
            rd_valid_out <= 1'b0;
        end else if (rd_en_in && !empty_out) begin
            rd_data_out <= evt_hist_bram[addr_in];
            rd_valid_out <= 1'b1;
        end else begin
            rd_valid_out <= 1'b0;
        end
    end


    assign count_out = data_count;
    assign full_out = (data_count == (HISTORY_DEPTH - 1));
    assign empty_out = (data_count == 0);


endmodule
