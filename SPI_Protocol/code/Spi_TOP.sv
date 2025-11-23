`timescale 1ns / 1ps


module Spi_TOP (
    input  logic       clk,
    input  logic       rst,
    input  logic       sw,
    input  logic       leftbtn,
    input  logic       rightbtn,
    // output logic [1:0] btn_test,
    output logic [7:0] rx_data,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);
    logic sclk;
    logic mosi;
    logic miso;
    logic cs;

    // assign btn_test[0] = leftbtn;
    // assign btn_test[1] = rightbtn;

    Spi_Master_Top U_master (.*);

    Spi_Slave_Top U_slave (
        .*,
        .reset(rst),
        .sclk(sclk),
        .cs(~cs)
    );
endmodule
