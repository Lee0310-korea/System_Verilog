`timescale 1ns / 1ps

module UART_RX (
    input  logic       clk,
    input  logic       rst,
    input  logic       tick,
    input  logic       rx,
    output logic [7:0] rx_data,
    output logic       rx_done
);
    parameter [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    logic[1:0] state, state_n;
    logic[7:0] rx_data_reg, rx_data_next;
    logic rx_done_reg, rx_done_next;
    logic[4:0] bit_count, bit_count_next;
    logic[2:0] data_count, data_count_next;

    assign rx_data = rx_data_reg;
    assign rx_done = rx_done_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            rx_data_reg <= 8'h00;
            rx_done_reg <= 1'b0;
            bit_count   <= 4'b0000;
            data_count  <= 3'b000;
        end else begin
            state       <= state_n;
            rx_data_reg <= rx_data_next;
            rx_done_reg <= rx_done_next;
            bit_count   <= bit_count_next;
            data_count  <= data_count_next;
        end
    end

    always_comb begin
        state_n         = state;
        rx_data_next    = rx_data_reg;
        rx_done_next    = rx_done_reg;
        bit_count_next  = bit_count;
        data_count_next = data_count;
        case (state)
            IDLE: begin
                rx_done_next = 1'b0;
                rx_data_next = 0;
                if (!rx) begin
                    state_n = START;
                    bit_count_next = 0;
                    data_count_next = 0;
                end
            end
            START: begin
                rx_done_next = 1'b0;
                if (tick) begin
                    if (bit_count == 7) begin
                        state_n = DATA;
                        bit_count_next = 0;
                        data_count_next = 0;
                    end else begin
                        bit_count_next = bit_count + 1;
                    end
                end
            end
            DATA: begin
                rx_data_next[7] = rx;
                rx_done_next = 1'b0;
                if (tick) begin
                    if (bit_count == 15) begin
                        bit_count_next = 0;
                        if (data_count == 7) begin
                            state_n = STOP;
                            bit_count_next = 0;
                            data_count_next = 0;
                        end else begin
                            rx_data_next = rx_data_reg >> 1;
                            data_count_next = data_count + 1;
                        end
                    end else begin
                        bit_count_next = bit_count + 1;
                    end
                end
            end
            STOP: begin
                if (tick) begin
                    if (bit_count == 15) begin
                        if (rx) begin
                            state_n = IDLE;
                            bit_count_next = 0;
                            data_count_next = 0;
                            rx_done_next = 1'b1;
                        end
                    end else begin
                        bit_count_next = bit_count + 1;
                    end
                end
            end
        endcase
    end
endmodule
