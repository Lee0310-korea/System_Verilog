`timescale 1ns / 1ps

module Spi_Slave (
    input  logic        clk,
    input  logic        sclk,
    input  logic        reset,
    input  logic        mosi,
    input  logic        cs,
    output logic        miso,
    output logic [15:0] received_data
);

    typedef enum {
        IDLE,
        RECEIVING_BYTE_0,
        RECEIVING_BYTE_1
    } state_t;

    state_t state, state_next;
    logic sclk_prev;

    logic [7:0] byte_reg;
    logic [2:0] bit_counter;
    logic [15:0] stored_data;
    logic sclk_posedge;

    assign sclk_posedge  = (sclk && !sclk_prev);
    assign received_data = stored_data;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            sclk_prev   <= 1'b0;
            bit_counter <= 0;
            byte_reg    <= 8'h00;
            stored_data <= 16'h0000;
        end else begin
            if (!cs) begin
                bit_counter <= 0;
                byte_reg    <= 8'h00;
                sclk_prev   <= 0;
            end else begin
                state     <= state_next;
                sclk_prev <= sclk;
                if (sclk_posedge) begin
                    byte_reg <= {byte_reg[6:0], mosi};
                    bit_counter <= bit_counter + 1;
                    if (state == RECEIVING_BYTE_0) begin
                        miso <= stored_data[0];
                    end else if (state == RECEIVING_BYTE_1) begin
                        miso <= stored_data[8];
                    end
                    if (bit_counter == 7) begin
                        if (state == RECEIVING_BYTE_0) begin
                            stored_data[7:0] <= {byte_reg[6:0], mosi};
                        end else if (state == RECEIVING_BYTE_1) begin
                            stored_data[15:8] <= {byte_reg[6:0], mosi};
                        end
                        bit_counter <= 0;
                        byte_reg    <= 8'h00;
                    end
                end
            end
        end
    end

    always_comb begin
        state_next = state;
        case (state)
            IDLE: begin
                if (cs) begin
                    state_next = RECEIVING_BYTE_0;
                end
            end

            RECEIVING_BYTE_0: begin
                if (bit_counter == 7 && sclk_posedge) begin
                    state_next = RECEIVING_BYTE_1;
                end
            end

            RECEIVING_BYTE_1: begin
                if (bit_counter == 7 && sclk_posedge) begin
                    state_next = IDLE;
                end
            end
        endcase
    end

endmodule

