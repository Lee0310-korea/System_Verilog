
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
    output logic        PREADY,
    output logic [3:0]  led_out  // LED 제어 출력 추가
);
    logic w_b_tick;
    logic w_start;
    logic rx_done;
    logic [7:0] w_rx_data, w_rx_fifo_popdata, w_tx_fifo_popdata, w_send_data;
    logic w_rx_empty, w_tx_fifo_full, w_tx_fifo_empty;
    logic w_tx_busy;
    logic send_push;
    logic [31:0] mux_out;
    logic [7:0] led_ctrl;  // LED 제어 레지스터 출력

    baud_tick_gen u_BAUD_TICK_GEN (
        .clk(clk),
        .reset(reset),
        .b_tick(w_b_tick)
    );

    uart_tx u_uart_tx (
        .clk(clk),
        .reset(reset),
        .start_trigger(~w_tx_fifo_empty),
        .tx_data(w_tx_fifo_popdata),
        .b_tick(w_b_tick),
        .tx(tx),
        .tx_busy(w_tx_busy)
    );

    fifo u_tx_FIFO (
        .clk(clk),
        .reset(reset),
        .push_data(w_rx_fifo_popdata),
        .push(~w_rx_empty),
        .pop(~w_tx_busy),
        .pop_data(w_tx_fifo_popdata),
        .full(w_tx_fifo_full),
        .empty(w_tx_fifo_empty)
    );

    uart_rx u_uart_rx (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(rx_done)
    );

    fifo u_rx_FIFO (
        .clk(clk),
        .reset(reset),
        .push_data(w_rx_data),
        .push(rx_done),
        .pop(~w_tx_fifo_full),
        .pop_data(w_rx_fifo_popdata),
        .full(),
        .empty(w_rx_empty)
    );

    APB_SlaveInterf_UART U_APB_SlaveInterf_UART (
        .PCLK(clk),
        .PRESET(reset),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PSEL(PSEL),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .tx_busy(w_tx_busy),
        .led_ctrl(led_out)  // LED 제어 신호 연결
    );


endmodule



module baud_tick_gen (
    input  logic clk,
    input  logic reset,
    output logic b_tick
);
    //baudrate
    parameter BAUDRATE = 9600 * 16;
    //State
    localparam BAUD_COUNT = 100_000_000 / BAUDRATE;
    reg [$clog2(BAUD_COUNT)-1:0] counter_reg, counter_next;
    reg tick_reg, tick_next;
    //SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            tick_reg <= 0;
        end else begin
            counter_reg <= counter_next;
            tick_reg <= tick_next;
        end
    end
    //next CL
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


module fifo (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] push_data,
    input  logic       push,
    input  logic       pop,
    output logic [7:0] pop_data,
    output logic       full,
    output logic       empty
);
    logic [1:0] w_wptr;
    logic [1:0] w_rptr;

    register_file U_REG_FILE (
        .clk(clk),
        .wptr(w_wptr),
        .rptr(w_rptr),
        .push_data(push_data),
        .wr(~full & push),
        .pop_data(pop_data)
    );


    fifo_cu U_FIFO_CU (
        .clk  (clk),
        .reset(reset),
        .push (push),
        .pop  (pop),
        .wptr (w_wptr),
        .rptr (w_rptr),
        .full (full),
        .empty(empty)
    );

endmodule

module register_file (
    input  logic       clk,
    input  logic [1:0] wptr,
    input  logic [1:0] rptr,
    input  logic [7:0] push_data,
    input  logic       wr,
    output logic [7:0] pop_data

);

    reg [7:0] ram[0:3];

    assign pop_data = ram[rptr];

    always @(posedge clk) begin
        if (wr) begin
            ram[wptr] <= push_data;
        end
    end
endmodule

module fifo_cu (
    input logic clk,
    input logic reset,
    input logic push,
    input logic pop,
    output logic [1:0] wptr,
    output logic [1:0] rptr,
    output logic full,
    output logic empty
);
    // output logic 
    reg [1:0] wptr_reg, wptr_next;
    reg [1:0] rptr_reg, rptr_next;
    reg full_reg, full_next;
    reg empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
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

    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            push, pop
        })
            2'b01: begin
                // pop
                full_next = 1'b0;
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b10: begin
                // push   
                empty_next = 1'b0;
                if (!full_reg) begin
                    wptr_next = wptr_reg + 1;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b11: begin
                if (empty_reg == 1'b1) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else if (full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else begin
                    // not be full, empty
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end
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
    //bit count
    reg [2:0] bit_cnt, bit_cnt_next;
    //tick_count
    reg [4:0] b_tick_cnt, b_tick_cnt_next;
    reg rx_done_reg, rx_done_next;
    //rx_internal buffer
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
                // bit_cnt_next = 0;
                // b_tick_cnt_next = 0;
                rx_done_next = 1'b0;
                if (b_tick) begin
                    if (rx == 0) begin
                        next_state = START;
                        b_tick_cnt_next = 0;
                    end
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt == 23) begin
                        next_state = DATA;
                        bit_cnt_next = 0;
                        b_tick_cnt_next = 0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick == 1) begin
                    if (b_tick_cnt == 0) begin
                        rx_buf_next[7] = rx;
                    end
                    if (b_tick_cnt == 15) begin
                        if (bit_cnt == 7) begin
                            next_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt + 1;
                            b_tick_cnt_next = 0;
                            rx_buf_next = rx_buf_reg >> 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick == 1) begin
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
    //fsmstate
    localparam [2:0] IDLE = 3'h0, WAIT = 3'h1, START = 3'h2, DATA = 3'h3, STOP = 3'h4;


    // state
    reg [2:0] state, next;
    // bit control reg
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    // tx internal buffer
    reg [7:0] data_reg, data_next;
    // b_tick_count
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    // output logic
    reg tx_reg, tx_next;
    reg tx_busy_reg, tx_busy_next;
    //output logic tx
    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;
    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state          <= IDLE;
            tx_reg         <= 1'b1;  // idle output logic is high
            b_tick_cnt_reg <= 0;
            bit_cnt_reg    <= 0;
            data_reg       <= 0;
            tx_busy_reg    <= 1'b0;
        end else begin
            state          <= next;
            tx_reg         <= tx_next;
            data_reg       <= data_next;
            bit_cnt_reg    <= bit_cnt_next;
            tx_busy_reg    <= tx_busy_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
        end
    end

    // next_CL
    always @(*) begin

        // remove latch
        next            = state;
        tx_next         = tx_reg;
        bit_cnt_next    = bit_cnt_reg;
        data_next       = data_reg;
        tx_busy_next    = tx_busy_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        case (state)
            IDLE: begin
                //output logic tx
                tx_next = 1'b1;
                tx_busy_next = 1'b0;
                if (start_trigger == 1'b1) begin
                    tx_busy_next = 1'b1;
                    next         = WAIT;
                    data_next    = tx_data;
                end
            end
            WAIT: begin
                if (b_tick == 1) begin
                    b_tick_cnt_next = 0;
                    next = START;
                end
            end
            START: begin
                //output logic tx
                tx_next = 1'b0;
                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next    = 0;
                        next            = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                //output logic tx <= tx_data[0]
                tx_next = data_reg[0];
                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            next = STOP;
                        end else begin
                            b_tick_cnt_next = 0;
                            bit_cnt_next = bit_cnt_reg + 1;
                            data_next    = data_reg >> 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        tx_busy_next = 0;
                        next = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
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
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    input  logic        tx_busy,
    output logic [3:0]  led_ctrl  // LED 제어 출력 추가
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4;

    assign led_ctrl = slv_reg4[7:0];  // slv_reg4의 하위 8비트를 LED 출력으로 사용

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
            slv_reg4 <= 0;  // LED 제어 레지스터 초기화
            PREADY   <= 0;
        end else begin
            PREADY <= 1'b0;
            slv_reg2[0] <= tx_busy;  // tx_busy 상태 반영

            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        2'd2: slv_reg2 <= PWDATA;
                        2'd3: slv_reg4 <= PWDATA;  // UART_LED_CTRL (0x10)
                    endcase
                end else begin
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg4;  // UART_LED_CTRL 읽기
                    endcase
                end
            end
        end
    end
endmodule



