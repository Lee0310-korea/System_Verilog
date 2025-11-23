`timescale 1ns / 1ps


module Spi_Slave_Top (
    input  logic       clk,
    input  logic       reset,
    input  logic       sclk,
    input  logic       mosi,
    input  logic       cs,
    output logic       miso,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);
    logic [15:0] data;


    fnd_controll U_fnd (
        .clk(clk),
        .rst(reset),
        .counter_10hz(data[13:0]),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    Spi_Slave U_spi_slave (
        .clk          (clk),
        .reset        (reset),
        .sclk         (sclk),
        .mosi         (mosi),
        .miso         (miso),
        .cs           (cs),
        .received_data(data)
    );

endmodule
