`timescale 1ns/1ps


module timestamp_counter #(
    parameter INPUT_CLK_FREQ_HZ = 50_000_000
) (
    input logic clk,
    input logic rst_n,

    output logic [31 : 0] timestamp,

    output logic tick_1us
);

    localparam CLKS_PER_1US = INPUT_CLK_FREQ_HZ / 1_000_000 - 1;
    localparam CNT_WIDTH = $clog2(CLKS_PER_1US + 1);

    
    logic [CNT_WIDTH - 1 : 0] timer_cnt;


    //--- timer_cnt ---
    always_ff @(posedge clk or negedge rst_n ) begin
        if (!rst_n) begin
            timer_cnt <= '0;
        end else begin
            if (timer_cnt == CLKS_PER_1US) begin
                timer_cnt <= '0;
            end else begin
                timer_cnt <= timer_cnt + 1;
            end
        end
    end


    //--- tick_1us ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_1us <= 1'b0;
        end else if (timer_cnt == CLKS_PER_1US) begin
            tick_1us <= 1'b1;
        end else begin
            tick_1us <= 1'b0;
        end
    end


    //--- Free running timestamp ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timestamp <= '0;
        end else if (tick_1us) begin
            timestamp <= timestamp + 1'b1;
        end
    end


endmodule
