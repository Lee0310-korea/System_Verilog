`timescale 1ns / 1ps

//레지스터가 더 필요하다면 더늘려서 사용하는 걸로
//내부 회로는 자신의 설계에 맞게 변경가능
//교수님이 작성해주시는 건 기본틀을 뿐 짜는건 내맘대로
module APB_GPO (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [ 3:0] PADDR,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic [ 3:0] gpo
);
    logic [3:0] mode;
    logic [3:0] out_Data;

    APB_Slave_GPO_Interface U_APB_GPO_Intf (.*);

    GPO U_GPO (.*);

endmodule

module APB_Slave_GPO_Interface (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic [ 3:0] mode,
    output logic [ 3:0] out_Data
);

    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign mode = slv_reg0[3:0];
    assign out_Data = slv_reg1[3:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            PREADY <= 1'b0;
            if (PSEL & PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[2])
                        1'b0: slv_reg0 <= PWDATA;
                        1'b1: slv_reg1 <= PWDATA;
                        // 2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    case (PADDR[2])
                        1'd0: PRDATA <= slv_reg0;
                        1'd1: PRDATA <= slv_reg1;
                        // 2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase

                end
            end
        end
    end
endmodule

module GPO (
    input  logic [3:0] mode,
    input  logic [3:0] out_Data,
    output logic [3:0] gpo
);
    genvar i;
    generate  //조합회로일 경우에 사용가능
        for (i = 0; i < 4; i++) begin
            assign gpo[i] = mode[i] ? out_Data[i] : 1'bz;
        end
    endgenerate

endmodule
