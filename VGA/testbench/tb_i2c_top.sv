`timescale 1ns / 1ps


module tb_i2c_top ();

    logic clk, reset, SCL, done_led;
    wire SDA;

    i2c_top dut (
        .clk     (clk),
        .reset   (reset),
        // External port
        .SCL     (SCL),
        .SDA     (SDA),
        .done_led(done_led)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10;
        reset = 0;
    end

    task ov7670_(arguments);
        
    endtask //
endmodule
