`timescale 1ns / 1ps

module MCU (
    input logic clk,
    input logic reset,
    output logic [3:0] gpo
);

    logic [31:0] instrCode, instrMemAddr;
    logic [ 2:0] strb;
    logic        busWe;
    logic [31:0] busAddr;
    logic [31:0] busWData;
    logic [31:0] busRData;
    logic        transfer;
    logic        ready;
    logic [31:0] PADDR;
    logic        PWRITE;
    logic        PSEL;
    logic        PENABLE;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSEL_RAM;
    logic        PSEL_GPO;
    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_GPO;
    logic        PREADY_RAM;
    logic        PREADY_GPO;
    logic        write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;


    assign PCLK     = clk;
    assign PRESET   = reset;
    assign write    = busWe;
    assign addr     = busAddr;
    assign wdata    = busWData;
    assign busRData = rdata;

    ROM U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    CPU_RV32I U_RV32I (.*);

    APB_Manager U_APB_Manager (
        .*,
        .PSEL0  (PSEL_RAM),
        .PSEL1  (PSEL_GPO),
        .PSEL2  (),
        .PSEL3  (),
        .PRDATA0(PRDATA_RAM),
        .PRDATA1(PRDATA_GPO),
        .PRDATA2(),
        .PRDATA3(),
        .PREADY0(PREADY_RAM),
        .PREADY1(PREADY_GPO),
        .PREADY2(),
        .PREADY3()
    );
    RAM U_RAM (
        .*,
        .PSEL  (PSEL_RAM),
        .PRDATA(PRDATA_RAM),
        .PREADY(PREADY_RAM)
    );

    APB_GPO U_APB_GPO (
        .*,
        .PSEL  (PSEL_GPO),
        .PRDATA(PRDATA_GPO),
        .PREADY(PREADY_GPO)
    );
endmodule
