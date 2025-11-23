`timescale 1ns / 1ps

module Spi_Master_Top (
    input  logic       clk,
    input  logic       rst,
    input  logic       sw,
    input  logic       leftbtn,
    input  logic       rightbtn,
    output logic [7:0] rx_data,
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       cs
);
    logic        leftbtn_out;
    logic        rightbtn_out;
    logic [15:0] tx_data;
    logic        start;
    logic        tx_ready;
    logic        tx_done;

    butten_debounce U_left (
        .clk  (clk),
        .rst  (rst),
        .i_btn(leftbtn),
        .o_btn(leftbtn_out)
    );
    
    butten_debounce U_right (
        .clk  (clk),
        .rst  (rst),
        .i_btn(rightbtn),
        .o_btn(rightbtn_out)
    );


    Upcounter U_upcounter (
        .clk(clk),
        .rst(rst),
        .leftbtn(leftbtn_out),
        .rightbtn(rightbtn_out),
        .sw(sw),
        .tx_data(tx_data),
        .*
    );
    Spi_Master U_spi_master (.*);

endmodule
