module event_cd_bridge #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_ADDR_WIDTH = 4
)(
    //--- Write Domain ---
    input logic wclk_in,
    input logic wrst_n,

    //--- Read Domain ---
    input logic rclk_in,
    input logic rrst_n,

    //--- AER ---
    input logic aer_req_in,
    input logic [DATA_WIDTH - 1 : 0] aer_data_in, // {aer_addr, aer_pol}
    output logic aer_ack_out,

    //--- Downstream ---
    input logic sys_ren_in,
    output logic [DATA_WIDTH - 1 : 0] rdata_out,
    output logic rvalid_out
);

    //--- Write Domain ---
    logic pix_clk;
    logic pix_rst_n;
    logic [DATA_WIDTH - 1 : 0] wdata;
    logic wen;
    logic wfull;

    //--- Read Domain ---
    logic sys_clk;
    logic sys_rst_n;
    logic ren;
    logic rempty;

    //--- SYS ---
    typedef enum logic [1 : 0] {
        SYS_IDLE,
        SYS_ACK,
        SYS_WAIT_FOR_LOW
    } SYS_STATE_t;


    SYS_STATE_t sys_state;

    logic aer_req_sync_1, aer_req_sync_2, aer_req_sync;
    logic aer_ack_sync_1, aer_ack_sync_2, aer_ack_sync_3, aer_ack_sync_pulse;
    logic aer_ack, aer_ack_lvl_sig;


    assign pix_clk = wclk_in;
    assign pix_rst_n = wrst_n;

    assign sys_clk = rclk_in;
    assign sys_rst_n = rrst_n;

    
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aer_req_sync_1 <= 1'b0;
            aer_req_sync_2 <= 1'b0;
        end else begin
            aer_req_sync_1 <= aer_req_in;
            aer_req_sync_2 <= aer_req_sync_1;
        end
    end

    assign aer_req_sync = aer_req_sync_2;


    always_ff @(posedge pix_clk or negedge pix_rst_n) begin
        if (!pix_rst_n) begin
            aer_ack_sync_1 <= 1'b0;
            aer_ack_sync_2 <= 1'b0;
            aer_ack_sync_3 <= 1'b0;
        end else begin
            aer_ack_sync_1 <= aer_ack_lvl_sig;
            aer_ack_sync_2 <= aer_ack_sync_1;
            aer_ack_sync_3 <= aer_ack_sync_2;
        end
    end

    assign aer_ack_sync_pulse = aer_ack_sync_2 ^ aer_ack_sync_3;
    assign aer_ack_out = aer_ack_sync_pulse;


    assign wen = (wrst_n && aer_req_sync && !wfull ) ? 1'b1 : 1'b0;
    assign ren = (rrst_n && sys_ren_in && !rempty) ? 1'b1 : 1'b0;


    always_ff @(posedge rclk_in or negedge rrst_n) begin
        if (!rrst_n) begin
            sys_state <= SYS_IDLE;
        end else  begin
            case (sys_state)
                SYS_IDLE         : if (aer_req_sync && !wfull) sys_state <= SYS_ACK;
                SYS_ACK          : sys_state <= SYS_WAIT_FOR_LOW;
                SYS_WAIT_FOR_LOW : if (!aer_req_sync) sys_state <= SYS_IDLE;
                default          : sys_state <= SYS_IDLE;
            endcase
        end 
    end


    assign aer_ack = (sys_state == SYS_ACK);

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aer_ack_lvl_sig <= 1'b0;
        end else if (aer_ack) begin
            aer_ack_lvl_sig <= !aer_ack_lvl_sig;
        end else begin
            aer_ack_lvl_sig <= aer_ack_lvl_sig;
        end
    end

    
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) cdc_fifo (
        //--- Write Domain ---
        .wclk_in(wclk_in),
        .wrst_n(wrst_n),
        .wdata_in(wdata),
        .wen_in(wen),
        .wfull_out(wfull),

        //--- Read Domain ---
        .rclk_in(rclk_in),
        .rrst_n(rrst_n),
        .ren_in(ren),
        .rdata_out(rdata_out),
        .rvalid_out(rvalid_out),
        .rempty_out(rempty)
    );


endmodule
