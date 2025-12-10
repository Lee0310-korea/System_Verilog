`timescale 1ns / 1ps


module UART_TX (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] tx_data,
    input  logic       start_trigger,
    input  logic       tick,
    output logic       tx_busy,
    output logic       tx
);

    parameter [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    logic [3:0] bit_count, bit_count_next;
    logic [2:0] data_count, data_count_next;
    logic [7:0] data_reg, data_next;
    logic [1:0] state, state_n;
    logic r_tx_busy, r_tx_busy_n;
    logic r_tx, r_tx_n;

    assign tx_busy = r_tx_busy;
    assign tx      = r_tx;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            bit_count  <= 4'b0000;
            data_count <= 3'b000;
            r_tx_busy  <= 1'b0;
            data_reg   <= 8'h00;
            state      <= IDLE;
            r_tx       <= 1'b1;
        end else begin
            bit_count  <= bit_count_next;
            data_count <= data_count_next;
            r_tx_busy  <= r_tx_busy_n;
            data_reg   <= data_next;
            state      <= state_n;
            r_tx       <= r_tx_n;
        end
    end

    always_comb begin
        bit_count_next  = bit_count;
        data_count_next = data_count;
        state_n         = state;
        r_tx_busy_n     = r_tx_busy;
        data_next       = data_reg;
        r_tx_n          = r_tx;
        case (state)
            IDLE: begin
                r_tx_n = 1'b1;
                r_tx_busy_n = 1'b0;
                    if (start_trigger) begin
                        state_n = START;
                        data_next = tx_data;
                        bit_count_next = 0;
                    end
                end
            START: begin
                r_tx_n = 1'b0;
                r_tx_busy_n = 1'b1;
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
                r_tx_n = data_reg[0];
                r_tx_busy_n = 1'b1;
                if (tick) begin
                    if (bit_count == 15) begin
                        bit_count_next = 0;
                        if (data_count == 7) begin
                            state_n         = STOP;
                            data_count_next = 0;
                            bit_count_next  = 0;
                        end else begin
                            data_count_next = data_count + 1;
                            data_next       = data_reg >> 1;
                        end
                    end else begin
                        bit_count_next = bit_count + 1;
                    end
                end
            end
            STOP: begin
                r_tx_n = 1'b1;
                r_tx_busy_n = 1'b1;
                if (tick) begin
                    if (bit_count == 15) begin
                        state_n         = IDLE;
                        bit_count_next  = 0;
                        data_count_next = 0;
                    end else begin
                        bit_count_next = bit_count + 1;
                    end
                end
            end
        endcase
    end

endmodule
