`timescale 1ns / 1ps

module FIFO_top (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] wdata,
    input  logic       wr,
    input  logic       rd,
    output logic [7:0] rdata,
    output logic       full,
    output logic       empty
);
    logic [2:0] w_addr; 
    logic [2:0] r_addr;
    logic wr_en;
    
    assign wr_en = wr & ~full;
    register_file_ram U_register_file(
        .*,
        .wr(wr_en)
        );

    fifo_cu U_fifo_cu(.*);
    // logic [2:0] w_waddr, w_raddr;

    // fifo_cu U_fifo_cu (
    //     .clk   (clk),
    //     .rst   (rst),
    //     .wr    (wr),
    //     .rd    (rd),
    //     .w_addr(w_waddr),
    //     .r_addr(w_raddr),
    //     .full  (full),
    //     .empty (empty)
    // );

    // register_file_ram U_register_file (
    //     .clk   (clk),
    //     .wr     (wr),
    //     .w_addr(w_waddr),
    //     .r_addr(w_raddr),
    //     .wdata (w_data),
    //     .rdata (r_data)
    // );



endmodule

module fifo_cu #(
    parameter AWIDTH = 3
) (
    input  logic              clk,
    input  logic              rst,
    input  logic              wr,
    input  logic              rd,
    output logic [AWIDTH-1:0] w_addr,
    output logic [AWIDTH-1:0] r_addr,
    output logic              full,
    output logic              empty
);

    logic [AWIDTH-1:0] wptr_reg, wptr_next;
    logic [AWIDTH-1:0] rptr_reg, rptr_next;
    logic full_reg, full_next;
    logic empty_reg, empty_next;

    assign full   = full_reg;
    assign empty  = empty_reg;
    assign w_addr = wptr_reg;
    assign r_addr = rptr_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1'b1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            wr, rd
        })
            2'b01: begin  //pop
                full_next = 0;
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                        full_next = 0;
                    end
                end
            end
            2'b10: begin  //push
                empty_next = 0;
                if (!full_reg) begin
                    wptr_next = wptr_reg + 1;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b11: begin  //push&pop
                if (empty_reg == 1'b1) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else if (full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end


endmodule

module register_file_ram #(
    parameter AWIDTH = 3
) (
    input  logic              clk,
    input  logic              wr,
    input  logic [AWIDTH-1:0] w_addr,
    input  logic [AWIDTH-1:0] r_addr,
    input  logic [       7:0] wdata,
    output logic [       7:0] rdata
);
    logic [7:0] register_file[0:2**AWIDTH-1];

    assign rdata = register_file[r_addr];

    always_ff @(posedge clk) begin
        if (wr) begin
            register_file[w_addr] <= wdata;
        end
    end

endmodule
