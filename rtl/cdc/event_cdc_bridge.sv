module event_cdc_bridge #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_ADDR_WIDTH = 4
)(
    //--- pix/Write Domain ---
    input logic wclk_in,
    input logic wrst_n,

    //--- sys/Read Domain ---
    input logic rclk_in,
    input logic rrst_n,

    //--- pix/AER ---
    input logic pix_aer_req_in,
    input logic [DATA_WIDTH - 1 : 0] pix_aer_data_in, // {aer_addr, aer_pol}
    output logic pix_aer_ack_out,

    //--- Downstream (sys) ---
    output logic sys_aer_req_out,
    output logic [DATA_WIDTH - 1 : 0] sys_aer_data_out,
    input logic sys_aer_ack_in
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
    logic rvalid;
    logic rempty;

    //--- SYS ---
    typedef enum logic [1 : 0] {
        SYS_IDLE,
        SYS_ACK,
        SYS_WAIT_FOR_LOW
    } SYS_STATE_t;


    SYS_STATE_t sys_state;


    assign pix_clk = wclk_in;
    assign pix_rst_n = wrst_n;

    assign sys_clk = rclk_in;
    assign sys_rst_n = rrst_n;


    //--- pix domain ---
    assign wen = (wrst_n && pix_aer_req_in && !pix_aer_ack_out && !wfull ) ? 1'b1 : 1'b0;
    assign wdata = pix_aer_data_in;

    always_ff @(posedge pix_clk or negedge pix_rst_n) begin
        if (!pix_rst_n) begin
            pix_aer_ack_out <= 1'b0;
        end else if (wen) begin
            pix_aer_ack_out <= 1'b1;
        end else begin
            pix_aer_ack_out <= 1'b0;
        end
    end


    //--- sys domain ---
    always_ff @(posedge rclk_in or negedge rrst_n) begin
        if (!rrst_n) begin
            sys_state <= SYS_IDLE;
        end else  begin
            case (sys_state)
                SYS_IDLE         : if (!rempty) sys_state <= SYS_ACK;
                SYS_ACK          : if (sys_aer_ack_in) sys_state <= SYS_WAIT_FOR_LOW;
                SYS_WAIT_FOR_LOW : if (!sys_aer_ack_in) sys_state <= SYS_IDLE;
                default          : sys_state <= SYS_IDLE;
            endcase
        end 
    end

    assign ren = (sys_state == SYS_IDLE && !rempty);
    assign sys_aer_req_out = (sys_state == SYS_ACK);

    
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) cdc_fifo (
        //--- pix/Write Domain ---
        .wclk_in(wclk_in),
        .wrst_n(wrst_n),
        .wdata_in(wdata),
        .wen_in(wen),
        .wfull_out(wfull),

        //--- sys/Read Domain ---
        .rclk_in(rclk_in),
        .rrst_n(rrst_n),
        .ren_in(ren),
        .rdata_out(sys_aer_data_out),
        .rvalid_out(rvalid),
        .rempty_out(rempty)
    );


endmodule
