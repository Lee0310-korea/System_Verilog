`timescale 1ns / 1ps

module Upcounter (
    input  logic        clk,
    input  logic        rst,
    input  logic        leftbtn,
    input  logic        rightbtn,
    input  logic        sw,
    output logic        start,
    output logic [15:0] tx_data,
    input  logic        tx_done,
    input  logic        tx_ready
);
    logic w_clk_10hz;

    counter U_counter (
        .clk     (clk),
        .rst     (rst),
        .tick    (w_clk_10hz),
        .leftbtn (leftbtn),
        .sw      (sw),
        .start   (start),
        .rightbtn(rightbtn),
        .tx_done (tx_done),
        .tx_ready(tx_ready),
        .tx_data (tx_data)
    );

    tick_gen_10hz U_tick_gen_10hz (
        .clk          (clk),
        .rst          (rst),
        .rightbtn     (rightbtn),
        .tick_gen_10hz(w_clk_10hz)
    );

endmodule

module tick_gen_10hz (
    input  logic clk,
    input  logic rst,
    input  logic rightbtn,
    output logic tick_gen_10hz
);
    logic [$clog2(10000000)-1:0] r_counter;
    logic r_tick;

    assign tick_gen_10hz = r_tick;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_tick <= 0;
            r_counter <= 0;
        end else begin
            if (r_counter == 10000000 - 1) begin
                r_counter <= 0;
                r_tick <= 1;
            end else begin
                r_tick <= 0;
                r_counter <= r_counter + 1;
            end
            if (rightbtn) begin
                r_tick <= 0;
                r_counter <= 0;
            end
        end
    end

endmodule

module counter (
    input logic clk,
    input logic rst,
    input logic tick,
    input logic leftbtn,
    input logic sw,
    input logic rightbtn,
    input logic tx_done,
    input logic tx_ready,
    output logic start,
    output logic [15:0] tx_data
);

    logic [13:0] r_counter;
    logic        start_sel;
    logic        counter_sel;
    logic [ 7:0] counter1;
    logic [ 7:0] counter2;

    assign counter1 = r_counter[7:0];
    assign counter2 = {2'b00, r_counter[13:8]};
    assign tx_data  = {counter2, counter1};

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter   <= 0;
            start_sel   <= 0;
            counter_sel <= 1;
            start       <= 0;
        end else begin
            start <= 0;
            if (leftbtn) begin
                start_sel <= ~start_sel;
            end
            if (start_sel) begin
                if (sw) begin
                    if (tick) begin
                        if (r_counter < 0 || r_counter >10000) begin
                            r_counter <= 9999;
                        end else begin
                            r_counter <= r_counter - 1;
                            start <= 1'b1;
                        end
                    end

                end else begin
                    if (tick) begin
                        if (r_counter > 10000 - 1) begin
                            r_counter <= 0;
                        end else begin
                            r_counter <= r_counter + 1;
                            start     <= 1'b1;
                        end
                    end
                end
            end else begin
                r_counter <= r_counter;
            end
            if (rightbtn) begin
                if (sw) begin
                    r_counter <= 10000;
                    start_sel <= 0;
                    start     <= 1'b1;
                end else begin
                    r_counter <= 0;
                    start_sel <= 0;
                    start     <= 1'b1;
                end
            end
        end
    end

endmodule
