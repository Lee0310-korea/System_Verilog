`timescale 1ns / 1ps


// ( system clk / baud ) * clock time * 10bit;
parameter BUAD_RATE = 9600; // 1초에 9600bit 전송
parameter BAUD_DELAY = (100_000_000 / BUAD_RATE) * 10 * 10; // start bit부터 stop bit까지 걸리는 시간
parameter CLOCK_PERIOD_NS = 10; // 한클락당 주기
parameter BIT_PER_CLOCK = 10416; // 100MHz / 9600bps : 한 비트당 들어가는 시스템 클락 수
parameter BIT_PERIOD = BIT_PER_CLOCK * CLOCK_PERIOD_NS; // 클락 수 * 한클락 당 주기 = 1bit 당 걸리는 시간


// UART TX 인터페이스
interface uart_tx_interface;
    logic       clk;
    logic       rst;
    logic       tx_start;
    logic [7:0] tx_data;
    logic [7:0] received_data;
    logic [7:0] expected_data;
    logic       b_tick;
    logic       tx_busy;
    logic       tx;
endinterface

// UART 트랜잭션 정의
class transaction;
    // Driver가 DUT에 인가하는 신호
    rand logic tx_start;
    rand logic [7:0] tx_data;

    // Monitor가 DUT에서 캡처하는 신호
    logic tx_busy;
    logic tx;
    
    // 이 메서드는 트랜잭션 객체를 디스플레이하는 데 사용됩니다.
    task display(string name_s);
       $display("%t, [%s] tx_start = %d, tx_data = %h",
            $time, name_s, tx_start, tx_data);
    endtask
endclass

// 트랜잭션 생성기 (Generator)
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_event;

    int total_count = 0;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run(int count);
        repeat (count) begin
            total_count++;
            tr = new;
            // tx_start 신호는 0과 1 중에서 랜덤하게 선택
            // tx_data는 랜덤값으로 설정
            assert (tr.randomize() with { tr.tx_start == 1'b1; })
            else $display("[GEN] tr.randomize() error!");
            
            gen2drv_mbox.put(tr);
            tr.display("[GEN]");
            
            @(gen_next_event);
        end
    endtask
endclass

// 드라이버 (Driver)
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual uart_tx_interface uart_intf;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual uart_tx_interface uart_intf);
        this.gen2drv_mbox = gen2drv_mbox;
        this.uart_intf = uart_intf;
    endfunction

    task reset();
        uart_intf.rst = 1;
        uart_intf.tx_start = 0;
        uart_intf.tx_data = 8'h00;
        uart_intf.b_tick = 0;
        repeat (2) @(posedge uart_intf.clk);
        uart_intf.rst = 0;
        repeat (2) @(posedge uart_intf.clk);
        $display("[DRV] Reset done!");
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);

            $display("[DRV] Sending data: %h", tr.tx_data);
            uart_intf.tx_start = 1'b1;
            uart_intf.tx_data = tr.tx_data;
            uart_intf.expected_data = tr.tx_data;
            @(posedge uart_intf.clk);
            uart_intf.tx_start = 1'b0;
            
            // 전송 완료까지 대기
            wait(uart_intf.tx_busy);
            wait(!uart_intf.tx_busy);
            
            tr.display("[DRV]");
            
        end
    endtask
endclass

// 모니터 (Monitor)
class monitor;
    transaction tr;
    virtual uart_tx_interface uart_intf;
    mailbox #(transaction) mon2scb_mbox;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual uart_tx_interface uart_intf);
        this.mon2scb_mbox = mon2scb_mbox;
        this.uart_intf = uart_intf;
    endfunction

    task run ();
        forever begin
            @(negedge uart_intf.tx);

            #(BIT_PERIOD / 2);

            for(int bit_count = 0; bit_count < 8; bit_count = bit_count + 1) begin
                #(BIT_PERIOD);
                uart_intf.received_data[bit_count] = uart_intf.tx;
            end

            #(BIT_PERIOD);
            
            tr = new;
            tr.display("[MON]");
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

// 스코어보드 (Scoreboard)
class scoreboard;
    transaction tr;
    virtual uart_tx_interface uart_intf;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_event;

    int pass_count = 0, fail_count = 0;

    function new(mailbox#(transaction) mon2scb_mbox, virtual uart_tx_interface uart_intf, event gen_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.uart_intf = uart_intf;
        this.gen_next_event = gen_next_event;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("[SCB}");
            if (uart_intf.expected_data == uart_intf.received_data) begin
                $display("[SCB] PASS: Data match. Sent: %h, Received: %h", uart_intf.expected_data, uart_intf.received_data);
                pass_count++;
            end else begin
                $display("[SCB] FAIL: Data mismatch. Sent: %h, Received: %h", uart_intf.expected_data, uart_intf.received_data);
                fail_count++;
            end

            $display("---------------------------");
            ->gen_next_event;
        end
    endtask
endclass

// 환경 (Environment)
class environment;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    event gen_next_event;
    event mon_next_event;

    function new(virtual uart_tx_interface uart_intf);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen = new(gen2drv_mbox, gen_next_event);
        drv = new(gen2drv_mbox, uart_intf);
        mon = new(mon2scb_mbox, uart_intf);
        scb = new(mon2scb_mbox, uart_intf, gen_next_event);
    endfunction

    task report();
        $display("===========================");
        $display("======= Test Report ========");
        $display("===========================");
        $display("== Total Test : %d ==", gen.total_count);
        $display("== Pass Test : %d ==", scb.pass_count);
        $display("== Fail Test : %d ==", scb.fail_count);
        $display("===========================");
        $display("== Test bench is finished ==");
        $display("===========================");
    endtask

    task reset();
        drv.reset();
    endtask

    task run();
        fork
            gen.run(50); // 5개의 데이터 전송 시뮬레이션
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $display("finished");
        report();
        $stop;
    endtask
endclass

// 최상위 모듈 (Top Module)
module tb_uart_tx_top ();
    environment env;
    uart_tx_interface uart_if_tb ();
    
    // DUT(Device Under Test) 인스턴스화
    UART_TX dut (
        .clk(uart_if_tb.clk),
        .rst(uart_if_tb.rst),
        .start_trigger(uart_if_tb.tx_start),
        .tx_data(uart_if_tb.tx_data),
        .tick(uart_if_tb.b_tick),
        .tx_busy(uart_if_tb.tx_busy),
        .tx(uart_if_tb.tx)
    );
    
    // 보드 레이트 틱 생성기 인스턴스화
    baud_tick_gen bgen (
        .clk(uart_if_tb.clk),
        .rst(uart_if_tb.rst),
        .o_tick(uart_if_tb.b_tick)
    );
    
    // 클럭 생성
    always #5 uart_if_tb.clk = ~uart_if_tb.clk;

    initial begin
        uart_if_tb.clk = 0;
        env = new(uart_if_tb);
        env.reset();
        env.run();
    end
endmodule