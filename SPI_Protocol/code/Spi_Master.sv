`timescale 1ns / 1ps


module Spi_Master (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] tx_data,
    input  logic        start,
    output logic [ 7:0] rx_data,
    output logic        tx_ready,
    output logic        tx_done,
    output logic        sclk,
    output logic        mosi,
    input  logic        miso,
    output logic        cs
);

    localparam SCLK_PULSE = 49;

    typedef enum {
        IDLE,
        CP0,
        CP1
    } state_e;

    state_e state, state_next;

    logic [7:0] tx_data_reg, tx_data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic [$clog2(SCLK_PULSE)-1:0] sclk_counter_reg, sclk_counter_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic data_ch_reg, data_ch_next;

    assign rx_data = rx_data_reg;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state            <= IDLE;
            tx_data_reg      <= 0;
            rx_data_reg      <= 0;
            sclk_counter_reg <= 0;
            bit_count_reg    <= 0;
            data_ch_reg      <= 0;
        end else begin
            state            <= state_next;
            tx_data_reg      <= tx_data_next;
            rx_data_reg      <= rx_data_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_count_reg    <= bit_count_next;
            data_ch_reg      <= data_ch_next;
        end
    end

    always_comb begin
        state_next        = state;
        tx_data_next      = tx_data_reg;
        rx_data_next      = rx_data_reg;
        sclk_counter_next = sclk_counter_reg;
        bit_count_next    = bit_count_reg;
        data_ch_next      = data_ch_reg;
        tx_ready          = 1'b0;
        tx_done           = 1'b0;
        sclk              = 1'b0;
        mosi              = 1'b0;
        cs                = 1'b1;
        case (state)
            IDLE: begin
                tx_data_next = 0;
                rx_data_next = 0;
                tx_ready     = 1'b1;
                sclk         = 1'b0;
                if (start) begin
                    state_next   = CP0;
                    tx_data_next = tx_data[7:0];
                    data_ch_next = 0;
                end
                if (data_ch_reg) begin
                    state_next   = CP0;
                    tx_data_next = tx_data[15:8];
                end
            end
            CP0: begin
                cs   = 1'b0;
                sclk = 1'b0;
                if (sclk_counter_reg == SCLK_PULSE) begin
                    rx_data_next      = {rx_data_reg[6:0], miso};
                    sclk_counter_next = 0;
                    state_next        = CP1;

                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP1: begin
                cs   = 1'b0;
                sclk = 1'b1;
                mosi = tx_data_reg[7];
                if (sclk_counter_next == SCLK_PULSE) begin
                    sclk_counter_next = 0;
                    if (bit_count_reg == 7) begin
                        bit_count_next = 0;
                        tx_done        = 1'b1;
                        state_next     = IDLE;
                        if (data_ch_reg) begin
                            data_ch_next = 0;
                        end else begin
                            data_ch_next = 1;
                        end
                    end else begin
                        bit_count_next = bit_count_reg + 1;
                        tx_data_next = {tx_data_reg[6:0], 1'b0};
                        state_next = CP0;
                    end
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
        endcase
    end

endmodule
