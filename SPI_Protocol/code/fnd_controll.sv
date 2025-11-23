`timescale 1ns / 1ps

module fnd_controll (
    input  logic       clk,
    input  logic       rst,
    input  logic [13:0] counter_10hz,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);

    logic [ 3:0] w_digit_1;
    logic [ 3:0] w_digit_10;
    logic [ 3:0] w_digit_100;
    logic [ 3:0] w_digit_1000;
    logic [ 3:0] w_counter;
    logic [ 1:0] w_sel;
    logic        w_clk_1khz;


    clk_div_1khz U_clk_div_1khz (
        .clk       (clk),
        .rst       (rst),
        .o_clk_1khz(w_clk_1khz)
    );

    counter_4 U_counter_4 (
        .clk(w_clk_1khz),
        .rst(rst),
        .sel(w_sel)
    );

    digit_splitter U_digit_splitter (
        .bcd_data  (counter_10hz),
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000)
    );

    decorder_2x4 U_decorder_2x4 (
        .sel    (w_sel),
        .fnd_com(fnd_com)
    );

    mux_4x1 U_mux_4x1 (
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000),
        .sel       (w_sel),
        .bcd       (w_counter)
    );

    bcd_decorder U_bcd_decorder (
        .bcd     (w_counter),
        .fnd_data(fnd_data)
    );

endmodule


module clk_div_1khz (
    input  logic  clk,
    input  logic rst,
    output logic o_clk_1khz
);  //counter 100,000
    logic [$clog2(100000)-1:0] r_counter;

    logic r_clk_1khz;
    assign o_clk_1khz = r_clk_1khz;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter  <= 0;
            r_clk_1khz <= 1'b0;
        end else begin
            if (r_counter == 100000 - 1) begin
                r_counter  <= 0;
                r_clk_1khz <= 1'b1;
            end else begin
                r_counter  <= r_counter + 1;
                r_clk_1khz <= 1'b0;
            end
        end
    end

endmodule

module counter_4 (
    input        clk,
    input        rst,
    output [1:0] sel
);

    logic [1:0] counter;

    assign sel = counter;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            //initial
            counter <= 0;
        end else begin
            //operation
            counter <= counter + 1;
        end
    end

endmodule

module digit_splitter (

    input  logic [13:0] bcd_data,
    output logic [ 3:0] digit_1,
    output logic [ 3:0] digit_10,
    output logic [ 3:0] digit_100,
    output logic [ 3:0] digit_1000
);

    assign digit_1    = bcd_data % 10;
    assign digit_10   = (bcd_data / 10) % 10;
    assign digit_100  = (bcd_data / 100) % 10;
    assign digit_1000 = (bcd_data / 1000) % 10;

endmodule

module decorder_2x4 (
    input  logic [1:0] sel,
    output logic [3:0] fnd_com
);

    assign fnd_com = (sel==2'b00)?4'b1110:
                    (sel==2'b01)?4'b1101:
                    (sel==2'b10)?4'b1011:
                    (sel==2'b11)?4'b0111:4'b1111;

endmodule

module mux_4x1 (
    input  logic [3:0] digit_1,
    input  logic [3:0] digit_10,
    input  logic [3:0] digit_100,
    input  logic [3:0] digit_1000,
    input  logic [1:0] sel,
    output logic [3:0] bcd
);

    logic [3:0] r_bcd;
    assign bcd = r_bcd;

    always_comb begin
        case (sel)
            2'b00:   r_bcd = digit_1;
            2'b01:   r_bcd = digit_10;
            2'b10:   r_bcd = digit_100;
            2'b11:   r_bcd = digit_1000;
            default: r_bcd = digit_1;
        endcase
    end

endmodule

module bcd_decorder (
    input  logic [3:0] bcd,
    output logic [7:0] fnd_data
);

    always_comb  begin
        case (bcd)
            4'b0000: fnd_data = 8'hC0;
            4'b0001: fnd_data = 8'hF9;
            4'b0010: fnd_data = 8'hA4;
            4'b0011: fnd_data = 8'hB0;
            4'b0100: fnd_data = 8'h99;
            4'b0101: fnd_data = 8'h92;
            4'b0110: fnd_data = 8'h82;
            4'b0111: fnd_data = 8'hF8;
            4'b1000: fnd_data = 8'h80;
            4'b1001: fnd_data = 8'h90;
            // 4'b1010: fnd_data = 8'h88;
            // 4'b1011: fnd_data = 8'h83;
            // 4'b1100: fnd_data = 8'hC6;
            // 4'b1101: fnd_data = 8'hA1;
            // 4'b1110: fnd_data = 8'h86;
            // 4'b1111: fnd_data = 8'h8E;
            default: fnd_data = 8'hFF;
        endcase
    end

endmodule

