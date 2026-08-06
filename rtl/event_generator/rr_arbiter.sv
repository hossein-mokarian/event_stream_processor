module rr_arbiter #(
    parameter REQ_COUNT = 8
)(
    input logic clk,
    input logic rst_n,
    input logic en,

    input  logic [0 : REQ_COUNT - 1] req_in,
    output logic [0 : REQ_COUNT - 1] grant_out
);

    localparam N = REQ_COUNT;


    integer i, j, k, m;
    
    logic [0 : N - 1] rr_ptr;

    logic [0 : N - 1] req_mask;

    logic [0 : N - 1] mreq;
    logic [0 : N    ] mcarry;
    logic [0 : N - 1] mgrant;

    logic [0 : N - 1] preq;
    logic [0 : N    ] pcarry;
    logic [0 : N - 1] pgrant;

    logic [0 : N - 1] next_grant;
    

    //--- REQ Mask ---
    always_comb begin
        if (en) begin
            req_mask = {N{1'b1}};
            for (i = 0; i < N; i = i + 1) begin
                if (rr_ptr[i]) begin
                    req_mask = {N{1'b1}} >> (i + 1);
                end
            end
        end
    end

    //--- Fixed Priority Encoder (Masked path) ---
    assign mreq = req_in & req_mask;

    always_comb begin
        mcarry = {(N + 1){1'b0}};
        for (j = 0; j < N; j++) begin
            mgrant[j] = mreq[j] & ~mcarry[j];
            mcarry[j + 1] = mcarry[j] | mreq[j];
        end
    end

    //--- Fixed Priority Encoder (plain path) ---
    assign preq = req_in;

    always_comb begin
        pcarry = {(N + 1){1'b0}};
        for (k = 0; k < N; k++) begin
            pgrant[k] = preq[k] & ~pcarry[k];
            pcarry[k + 1] = pcarry[k] | preq[k];
        end
    end

    assign next_grant = mgrant ? mgrant : pgrant;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_ptr <= '0;
        end else begin
            rr_ptr <= next_grant;
        end
    end

    assign grant_out = rr_ptr;

endmodule
