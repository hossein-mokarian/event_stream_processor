`timescale 1ns/1ps

module tb_uart_tx;

    localparam INPUT_CLK_FREQ_HZ = 50_000;
    localparam BAUD_RATE = 10400;
    localparam UART_DATA_WIDTH = 8;

    localparam BIT_PERIOD = INPUT_CLK_FREQ_HZ / BAUD_RATE;

    logic clk = 0;
    logic rst_n = 0;
    logic [UART_DATA_WIDTH - 1 : 0] data;
    logic data_valid;
    wire tx;
    wire busy;

    uart_tx #(
        .INPUT_CLK_FREQ_HZ(INPUT_CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE),
        .UART_DATA_WIDTH(UART_DATA_WIDTH)
    ) dut (
        // General
        .clk(clk),
        .rst_n(rst_n),

        // Inputs
        .data_in(data),
        .data_valid_in(data_valid),

        // Outputs
        .tx_out(tx),
        .busy_out(busy)
    );

    // Clock Generator
    always #10 clk = ~clk;

    // Tasks
    task automatic send_data(input logic [UART_DATA_WIDTH - 1 : 0] tx_data);
        @(negedge clk);
        while (busy) begin
            @(negedge clk);
        end

        data <= tx_data;
        data_valid = 1'b1;

        @(negedge clk);
        data <= 0;
        data_valid = 1'b0;

        @(negedge clk);
        while (busy) begin
            @(negedge clk);
        end
    endtask //automatic

    task automatic check_data(output logic [UART_DATA_WIDTH - 1 : 0] rec_data);
        
        automatic logic [$clog2(UART_DATA_WIDTH + 2) - 1 : 0] bit_index;
        automatic logic [UART_DATA_WIDTH + 2 - 1 : 0] rx_buffer;
        automatic logic [$clog2(BIT_PERIOD) - 1 : 0] clk_cnt;

        rx_buffer = '0;
        bit_index = '0;
        clk_cnt = '0;

        while (!busy) begin
            @(negedge clk);
            $display("check_data: waiting for busy ...");
        end

        while (clk_cnt < BIT_PERIOD / 2) begin
            @(negedge clk);
            clk_cnt = clk_cnt + 1;
        end

        $display("check_data: rx: %h , bit_index: %d", tx, bit_index);
        rx_buffer[0] = tx;
        bit_index = bit_index + 1;
        clk_cnt = '0;

        while (bit_index < (UART_DATA_WIDTH + 2)) begin
            if (busy && clk_cnt == BIT_PERIOD - 1) begin
                $display("check_data: rx: %h , bit_index: %d", tx, bit_index);
                rx_buffer[bit_index] = tx;
                bit_index = bit_index + 1;
                clk_cnt = '0;
            end else begin
                clk_cnt = clk_cnt + 1;
            end

            @(negedge clk);
        end

        rec_data = rx_buffer[UART_DATA_WIDTH : 1];
        $display("check_data: start bit: %h", rx_buffer[0]);
        $display("check_data: rec_data: %h", rec_data);
        $display("check_data: stop bit: %h", rx_buffer[UART_DATA_WIDTH + 2 - 1]);

    endtask //automatic

    logic [UART_DATA_WIDTH - 1 : 0] tx_data;
    logic [UART_DATA_WIDTH - 1 : 0] rx_data;

    initial begin
        

        rst_n = 0;
        data = {{UART_DATA_WIDTH}{1'b1}};
        data_valid = 1'b0;
        tx_data = {{UART_DATA_WIDTH}{1'b1}};

        #220 rst_n = 1;
        
        tx_data = 'h23;
        fork
            begin
                send_data(tx_data);
            end

            begin
                check_data(rx_data);
            end
        join

        if (rx_data == tx_data) begin
            $display("SUCCESS: Data is sent. Match: %h", rx_data);
        end else begin
            $display("ERROR: Data is not sent properly! Sent: %h , Got: %h" , tx_data, rx_data);
        end

    end

    initial begin
        $dumpfile("tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
    end

endmodule
