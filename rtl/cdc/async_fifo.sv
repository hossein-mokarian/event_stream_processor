module async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    //--- Write Domain ---
    input logic wclk_in,
    input logic wrst_n,
    input logic [DATA_WIDTH - 1 : 0] wdata_in,
    input logic wen_in,
    output logic wfull_out,

    //--- Read Domain ---
    input logic rclk_in,
    input logic rrst_n,
    input logic ren_in,
    output logic [DATA_WIDTH - 1 : 0] rdata_out,
    output logic rvalid_out,
    output logic rempty_out
);

    localparam BUFF_DEPTH = 1 << ADDR_WIDTH;
    localparam PTR_WIDTH = ADDR_WIDTH + 1;


    //--- Buffer ---
    integer i;
    logic [DATA_WIDTH - 1 : 0] buff [0 : BUFF_DEPTH];

    //--- Write Ptrs ---
    logic [ADDR_WIDTH - 1 : 0] wptr_bin;
    logic [ADDR_WIDTH - 1 : 0] wptr_grey;

    //--- Read Ptrs ---
    logic [ADDR_WIDTH - 1 : 0] rptr_bin;
    logic [ADDR_WIDTH - 1 : 0] rptr_grey;

    //--- Syncronizer ---
    logic [PTR_WIDTH - 1 : 0] wptr_grey_r1;
    logic [PTR_WIDTH - 1 : 0] wptr_grey_r2;

    logic [PTR_WIDTH - 1 : 0] rptr_grey_w1;
    logic [PTR_WIDTH - 1 : 0] rptr_grey_w2;


    //--- Write Buffer ---
    always_ff @(posedge wclk_in or negedge wrst_n) begin
        if (!wrst_n) begin
            for (i = 0; i < BUFF_DEPTH; i++) begin
                buff[i] <= 0;
            end
        end else if (wen_in && !wfull_out) begin
            buff[wptr_bin] <= wdata_in;
        end
    end

    //--- Write Ptrs ---
    always_ff @(posedge wclk_in or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 0;
            wptr_grey <= 0;
        end else if (wen_in && !wfull_out) begin
            wptr_bin <= wptr_bin + 1;
            wptr_grey <= bin_2_grey(wptr_bin + 1);
        end
    end

    //--- Write Syncronizer ---
    always_ff @(posedge wclk_in or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_grey_w1 <= 0;
            rptr_grey_w2 <= 0;
        end else begin
            rptr_grey_w1 <= rptr_grey;
            rptr_grey_w2 <= rptr_grey_w2;
        end
    end

    //--- Full Flag ---
    assign wfull_out = (!wrst_n) ? 1'b0 : wptr_grey == {~rptr_grey_w2[PTR_WIDTH - 1 : PTR_WIDTH - 2], rptr_grey_w2[PTR_WIDTH - 3 : 0]};

    //--- Read buffer ---
    always_ff @(posedge rclk_in or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_out <= '0;
            rvalid_out <= 1'b0;
        end else if (ren_in && !rempty_out) begin
            rdata_out <= buff[rptr_bin];
            rvalid_out <= 1'b1;
        end else begin
            rvalid_out <= 1'b0;
        end
    end

    //--- Read Ptrs ---
    always_ff @(posedge rclk_in or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 0;
            rptr_grey <= 0;
        end else if (ren_in && !rempty_out) begin
            rptr_bin <= rptr_bin + 1;
            rptr_grey <= bin_2_grey(rptr_bin + 1);
        end
    end

    //--- Read Syncronizer ---
    always_ff @(posedge rclk_in or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_grey_r1 <= 0;
            wptr_grey_r2 <= 0;
        end else begin
            wptr_grey_r1 <= wptr_grey;
            wptr_grey_r2 <= wptr_grey_r1;
        end
    end

    //--- Empty Flag ---
    assign rempty_out = (!rrst_n) ? 1'b0 : (rptr_grey == wptr_grey_r2);

    //--- Helper function(s) ---
    function automatic logic [PTR_WIDTH - 1 : 0] bin_2_grey(
        logic [PTR_WIDTH - 1 : 0] bin
    );
        return (bin ^ (bin >> 1));
    endfunction

endmodule
