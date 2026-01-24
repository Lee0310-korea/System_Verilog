`timescale 1ns / 1ps


module OV7670_CCTV (
    input  logic       clk,
    input  logic       reset,
    // ov7670 side
    output logic       xclk,
    input  logic       pclk,
    input  logic       href,
    input  logic       vsync,
    input  logic [7:0] data,
    // vga port
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port,
    // I2C port
    output logic       SCL,
    inout  wire        SDA,
    output logic       done_led
);

    logic        sys_clk;
    logic        DE;
    logic [ 9:0] x_pixel;
    logic [ 9:0] y_pixel;
    logic [16:0] rAddr;
    logic [15:0] rData;
    logic        we;
    logic [16:0] wAddr;
    logic [15:0] wData;

    assign xclk = sys_clk;

    i2c_top U_I2C_TOP (
        .clk      (clk),
        .reset    (reset),
        // External port
        .SCL      (SCL),
        .SDA      (SDA),
        .done_led (done_led)
    );


    pixel_clk_gen U_PXL_CLK_GEN (
        .clk  (clk),
        .reset(reset),
        .pclk (sys_clk)
    );

    VGA_syncher U_VGA_Syncher (
        .clk    (sys_clk),
        .reset  (reset),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    ImgMemReader U_IMG_Reader (
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .addr   (rAddr),
        .imgData(rData),
        .r_port (r_port),
        .g_port (g_port),
        .b_port (b_port)
    );


    frame_buffer U_Frame_Buffer (
        // write side
        .wclk (pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        // read sie
        .rclk (sys_clk),
        .oe   (1),
        .rAddr(rAddr),
        .rData(rData)
    );


    OV7670_Mem_Controller U_OV7670_Mem_Controller (
        .pclk (pclk),
        .reset(reset),
        // OV7670 side
        .href (href),
        .vsync(vsync),
        .data (data),
        // memory side
        .we   (we),
        .wAddr(wAddr),  // 320 * 240
        .wdata(wData)
    );

endmodule
