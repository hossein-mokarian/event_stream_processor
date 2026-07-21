module blinker #(
    parameter int CLK_FREQ_HZ = 50_000_000,  // 50 MHz default
    parameter int BLINK_HZ    = 1
) (
    input  logic clk,
    input  logic rst_n,     // Active-low reset
    output logic led
);
    localparam int DIVIDER = CLK_FREQ_HZ / (2 * BLINK_HZ);

    logic [$clog2(DIVIDER)-1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            led     <= 1'b0;
        end else begin
            if (counter == DIVIDER - 1) begin
                counter <= '0;
                led     <= ~led;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
