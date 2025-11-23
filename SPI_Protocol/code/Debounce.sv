`timescale 1ns / 1ps



module butten_debounce (
    input  logic clk,
    input  logic rst,
    input  logic i_btn,
    output logic o_btn
);

    logic [$clog2(100)-1:0] counter_reg;
    logic clk_reg;
    logic [7:0] q_reg, q_next;
    logic  edge_reg;
    logic  debouce;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            clk_reg <= 1'b0;
        end else begin
            if (counter_reg == 100 - 1) begin
                counter_reg <= 0;
                clk_reg <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                clk_reg <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk_reg, posedge rst) begin
        if (rst) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    always_comb begin
        q_next = {i_btn, q_reg[7:1]};
    end

    assign debouce = &q_reg;  //4input AND

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debouce;
        end
    end

    assign o_btn = ~edge_reg & debouce;

endmodule