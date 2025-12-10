`timescale 1ns / 1ps

module UART_TOP (
    input  logic clk,
    input  logic rst,
    input  logic rx,
    output logic tx
);

    logic w_tick;
    logic [7:0] w_rx_data, w_tx_data, w_uart_data;
    logic w_done;
    logic w_tx_busy,w_tx_empty,w_rx_empty,w_tx_full;

    UART_TX U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tx_data(w_uart_data),
        .start_trigger(~w_tx_empty),
        .tick(w_tick),
        .tx_busy(w_tx_busy),
        .tx(tx)
    );

    baud_tick_gen U_baud_tick (
        .clk(clk),
        .rst(rst),
        .o_tick(w_tick)
    );

    UART_RX U_UART_RX (
        .clk(clk),
        .rst(rst),
        .tick(w_tick),
        .rx(rx),
        .rx_data(w_rx_data),
        .rx_done(w_done)
    );

    FIFO_top U_fifo_rx (
        .clk(clk),
        .rst(rst),
        .wdata(w_rx_data),
        .wr(w_done),
        .rd(~w_tx_full),
        .rdata(w_tx_data),
        .full(),
        .empty(w_rx_empty)
    );

    FIFO_top U_fifo_tx (
        .clk(clk),
        .rst(rst),
        .wdata(w_tx_data),
        .wr(~w_rx_empty),
        .rd(~w_tx_busy),
        .rdata(w_uart_data),
        .full(w_tx_full),
        .empty(w_tx_empty)
    );

endmodule

module baud_tick_gen (
    input  logic clk,
    input  logic rst,
    output logic o_tick
);

    parameter BAUD = 9600;
    parameter BAUD_TICK_COUNT = 100_000_000 / BAUD / 16;

    logic [$clog2(BAUD_TICK_COUNT)-1:0] counter_reg;
    logic tick_reg;

    assign o_tick = tick_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_reg <= 1'b0;
        end else begin
            if (counter_reg == BAUD_TICK_COUNT) begin
                counter_reg <= 0;
                tick_reg <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                tick_reg <= 1'b0;
            end
        end
    end
endmodule
