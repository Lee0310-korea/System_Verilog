`timescale 1ns / 1ps


module uart_top (
    input  logic        clk,
    input  logic        reset,
    input  logic        rx,
    output logic        tx,
    input  logic [ 3:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY
);

    // 내부 신호
    logic w_b_tick;
    logic [7:0] w_rx_data;
    logic w_rx_done;
    logic tx_start;
    logic [7:0] tx_data;
    logic tx_busy;

    // Baud tick generator
    baud_tick_gen u_baud (
        .clk(clk),
        .reset(reset),
        .b_tick(w_b_tick)
    );

    // UART RX
    uart_rx u_rx (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    // UART TX
    uart_tx u_tx (
        .clk(clk),
        .reset(reset),
        .start_trigger(tx_start),
        .tx_data(tx_data),
        .b_tick(w_b_tick),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // APB Slave Interface (FIFO 없이)
    APB_SlaveInterf_UART u_apb (
        .PCLK       (clk),
        .PRESET     (reset),
        .PADDR      (PADDR),
        .PWRITE     (PWRITE),
        .PENABLE    (PENABLE),
        .PSEL       (PSEL),
        .PRDATA     (PRDATA),
        .PREADY     (PREADY),
        .PWDATA     (PWDATA),
        .rx_data    (w_rx_data),
        .rx_valid   (w_rx_done),
        .rx_empty   (1'b0),       // FIFO 없으므로 항상 0
        .tx_full    (tx_busy),
        .fifo_pop   (tx_start),   // APB 쓰기 시 바로 TX start
        .tx_data_out(tx_data)     // TX 데이터 직접 연결
    );

endmodule

module baud_tick_gen (
    input  logic clk,
    input  logic reset,
    output logic b_tick
);
    parameter BAUDRATE = 9600 * 16;  // 16x oversampling
    localparam BAUD_COUNT = 100_000_000 / BAUDRATE;
    reg [$clog2(BAUD_COUNT)-1:0] counter_reg, counter_next;
    reg tick_reg, tick_next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            tick_reg <= 0;
        end else begin
            counter_reg <= counter_next;
            tick_reg <= tick_next;
        end
    end

    always @(*) begin
        counter_next = counter_reg;
        tick_next = tick_reg;
        if (counter_reg == BAUD_COUNT - 1) begin
            counter_next = 0;
            tick_next = 1'b1;
        end else begin
            counter_next = counter_reg + 1;
            tick_next = 1'b0;
        end
    end

    assign b_tick = tick_reg;
endmodule

module uart_rx (
    input  logic       clk,
    input  logic       reset,
    input  logic       rx,
    input  logic       b_tick,
    output logic [7:0] rx_data,
    output logic       rx_done
);
    localparam [1:0] IDLE = 2'h0, START = 2'h1, DATA = 2'h2, STOP = 2'h3;
    reg [1:0] cur_state, next_state;
    reg [2:0] bit_cnt, bit_cnt_next;
    reg [4:0] b_tick_cnt, b_tick_cnt_next;
    reg rx_done_reg, rx_done_next;
    reg [7:0] rx_buf_reg, rx_buf_next;

    assign rx_data = rx_buf_reg;
    assign rx_done = rx_done_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            cur_state   <= IDLE;
            bit_cnt     <= 0;
            b_tick_cnt  <= 0;
            rx_done_reg <= 0;
            rx_buf_reg  <= 0;
        end else begin
            cur_state   <= next_state;
            bit_cnt     <= bit_cnt_next;
            b_tick_cnt  <= b_tick_cnt_next;
            rx_done_reg <= rx_done_next;
            rx_buf_reg  <= rx_buf_next;
        end
    end

    always @(*) begin
        next_state      = cur_state;
        bit_cnt_next    = bit_cnt;
        b_tick_cnt_next = b_tick_cnt;
        rx_done_next    = rx_done_reg;
        rx_buf_next     = rx_buf_reg;

        case (cur_state)
            IDLE: begin
                rx_done_next = 1'b0;
                if (b_tick && rx == 0) begin
                    next_state = START;
                    b_tick_cnt_next = 0;
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt == 23) begin
                        next_state = DATA;
                        bit_cnt_next = 0;
                        b_tick_cnt_next = 0;
                    end else b_tick_cnt_next = b_tick_cnt + 1;
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt == 0) rx_buf_next[7] = rx;
                    if (b_tick_cnt == 15) begin
                        if (bit_cnt == 7) next_state = STOP;
                        else begin
                            bit_cnt_next = bit_cnt + 1;
                            b_tick_cnt_next = 0;
                            rx_buf_next = rx_buf_reg >> 1;
                        end
                    end else b_tick_cnt_next = b_tick_cnt + 1;
                end
            end
            STOP: begin
                if (b_tick) begin
                    rx_done_next = 1'b1;
                    next_state   = IDLE;
                end
            end
        endcase
    end
endmodule

module uart_tx (
    input logic clk,
    input logic reset,
    input logic start_trigger,
    input logic [7:0] tx_data,
    input logic b_tick,
    output logic tx,
    output logic tx_busy
);
    localparam [2:0] IDLE = 3'h0, WAIT = 3'h1, START = 3'h2, DATA = 3'h3, STOP = 3'h4;
    reg [2:0] state, next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] data_reg, data_next;
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg tx_reg, tx_next;
    reg tx_busy_reg, tx_busy_next;

    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tx_reg <= 1'b1;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg <= 0;
            data_reg <= 0;
            tx_busy_reg <= 1'b0;
        end else begin
            state <= next;
            tx_reg <= tx_next;
            data_reg <= data_next;
            bit_cnt_reg <= bit_cnt_next;
            tx_busy_reg <= tx_busy_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
        end
    end

    always @(*) begin
        next = state;
        tx_next = tx_reg;
        bit_cnt_next = bit_cnt_reg;
        data_next = data_reg;
        tx_busy_next = tx_busy_reg;
        b_tick_cnt_next = b_tick_cnt_reg;

        case (state)
            IDLE: begin
                tx_next = 1'b1;
                tx_busy_next = 1'b0;
                if (start_trigger) begin
                    tx_busy_next = 1'b1;
                    next = WAIT;
                    data_next = tx_data;
                end
            end
            WAIT:
            if (b_tick) begin
                b_tick_cnt_next = 0;
                next = START;
            end
            START: begin
                tx_next = 1'b0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next = 0;
                        next = DATA;
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1;
                end
            end
            DATA: begin
                tx_next = data_reg[0];
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) next = STOP;
                        else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                            data_next = data_reg >> 1;
                        end
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1;
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        tx_busy_next = 0;
                        next = IDLE;
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1;
                end
            end
        endcase
    end
endmodule
module APB_SlaveInterf_UART (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [ 3:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    input  logic [ 7:0] rx_data,
    input  logic        rx_valid,
    input  logic        rx_empty,    // 항상 0
    input  logic        tx_full,
    output logic        fifo_pop,    // TX 시작 신호
    output logic [ 7:0] tx_data_out  // TX 데이터로 전달
);

    logic [31:0] slv_data;
    logic [31:0] slv_status;

    // RX 데이터를 저장하고, 상태 업데이트
    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_data   <= 32'd0;
            slv_status <= 32'd0;
        end else begin
            if (rx_valid) begin
                slv_data <= {{24{1'b0}}, rx_data};
            end
            slv_status[0] <= rx_empty;
            slv_status[1] <= tx_full;
        end
    end

    // APB 읽기/쓰기 및 TX 제어
    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            PRDATA      <= 32'd0;
            PREADY      <= 1'b0;
            fifo_pop    <= 1'b0;
            tx_data_out <= 8'd0;
        end else begin
            PREADY   <= 1'b0;
            fifo_pop <= 1'b0;

            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;

                // CPU 쓰기: UART_TXDATA에 값 쓰면 바로 TX 시작
                if (PWRITE) begin
                    if (!tx_full) begin
                        tx_data_out <= PWDATA[7:0];
                        fifo_pop    <= 1'b1;
                    end
                end  // CPU 읽기: RX 데이터 및 상태
                else begin
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_data;  // RX 데이터
                        2'd1: PRDATA <= slv_status;  // 상태
                        default: PRDATA <= 32'd0;
                    endcase
                end
            end

            // RX 데이터가 들어오면 loopback으로 TX
            if (rx_valid && !tx_full) begin
                tx_data_out <= rx_data;
                fifo_pop    <= 1'b1;
            end
        end
    end

endmodule
