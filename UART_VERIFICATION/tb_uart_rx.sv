`timescale 1ns / 1ps
interface rx_interface;
    logic clk;
    logic rst;
    logic rx;
    logic [7:0] ran_data;
    logic [7:0] rx_data;
    logic rx_done;
endinterface

class transaction;
    rand bit [7:0] ran_data;
    bit [7:0] rx_data;
    bit rx_done;

    task display(string name_s);
        $display("%t, [%s] ran_data = %d, rx_data = %d, rx_done = %d", $time,
                 name_s, ran_data, rx_data, rx_done);
    endtask
endclass

class generator;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_event;

    int total_count = 0;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_event); // new안에 있는 gen2drv 애들은 env에서 실체화를 시킴 
        this.gen2drv_mbox   = gen2drv_mbox; // 1.gen2drv는 설계도 2. gen2drv는 실체
        this.gen_next_event = gen_next_event;
    endfunction

    task run(int count);
        repeat (count) begin
            total_count++;
            tr = new;
            assert (tr.randomize())
            else $display("[GEN] tr.randomize() error!!!");
            gen2drv_mbox.put(tr);
            tr.display("[GEN]");
            @(gen_next_event);
        end

    endtask
endclass

class driver;

    parameter BAUD_RATE = 9600;
    parameter CLOCK_PERIOD_NS = 10;  //100Mhz
    parameter BITPERCLOCK = 100_000_000 / BAUD_RATE; //10416;  // 1 / BAUD_RATE;  // 1bit per clock 1/9600
    parameter BIT_PERIOD =BITPERCLOCK * CLOCK_PERIOD_NS;  //number of clock * 10ns

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual rx_interface rx_intf;
    event mon_next_event;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual rx_interface rx_intf, event mon_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.rx_intf = rx_intf;
        this.mon_next_event = mon_next_event;
    endfunction

    task reset();
        rx_intf.clk = 0;
        rx_intf.rst = 1;
        rx_intf.rx = 1;
        rx_intf.ran_data = 0;
        @(posedge rx_intf.clk) rx_intf.rst = 0;
        $display("[DRV] reset done!"); 
    endtask



    task run();
        forever begin
            gen2drv_mbox.get(tr);
            rx_intf.ran_data = tr.ran_data;
            rx_intf.rx = 1;
            #(BIT_PERIOD);
            rx_intf.rx = 0;
            #(BIT_PERIOD);

            for (int i = 0; i < 8; i++) begin
                rx_intf.rx = tr.ran_data[i];
                #(BIT_PERIOD);
            end
            rx_intf.rx = 1;
            tr.display("[DRV]");
            ->mon_next_event; // 
            // #(BIT_PERIOD);
            @(posedge rx_intf.clk); // 5
        end
    endtask
endclass

class monitor;
    transaction tr;
    virtual rx_interface rx_intf;
    mailbox #(transaction) mon2scb_mbox;
    event mon_next_event;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual rx_interface rx_intf, event mon_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.rx_intf = rx_intf;
        this.mon_next_event = mon_next_event;
    endfunction

    task run();
        forever begin
            @(mon_next_event);
            tr = new;
            tr.ran_data = rx_intf.ran_data;
            tr.rx_done = rx_intf.rx_done;
            tr.rx_data = rx_intf.rx_data;
            tr.display("MON");
            mon2scb_mbox.put(tr);
            @(posedge rx_intf.clk);
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_event;

    int pass_count = 0, fail_count = 0;


    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_event);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("SCB");
            if (tr.rx_data == tr.ran_data) begin
                pass_count++;
                $display("[SCB] PASS: %d", tr.rx_data);
            end else begin
                fail_count++;
                $display("[SCB] FAIL: rx_data=%d expected=%d", tr.rx_data,
                         tr.ran_data);
            end
            ->gen_next_event;
        end

    endtask  //
endclass

class environment;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    generator gen;
    driver drv;
    event gen_next_event;
    event mon_next_event;
    monitor mon;
    scoreboard scb;

    function new(virtual rx_interface rx_intf);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_event);
        drv = new(gen2drv_mbox, rx_intf, mon_next_event);
        mon = new(mon2scb_mbox, rx_intf, mon_next_event);
        scb = new(mon2scb_mbox, gen_next_event);
    endfunction

    task report();
        $display("===========================");
        $display("=======test report ========");
        $display("===========================");
        $display("==    Total Test : %d    ==", gen.total_count);
        $display("==    Pass Test : %d     ==", scb.pass_count);
        $display("==    Fail Test : %d     ==", scb.fail_count);
        $display("===========================");
        $display("==  Test bench is finish ==");
        $display("===========================");

    endtask  //

    task reset();
        drv.reset();
    endtask

    task run();
        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        report();
        $display("finished");
        $stop;
    endtask
endclass

module tb_rx_data_ver ();

    environment env;
    rx_interface rx_intf_tb ();

    logic w_b_tick;

    UART_RX dut (
        .clk    (rx_intf_tb.clk),
        .rst    (rx_intf_tb.rst),
        .tick (w_b_tick),
        .rx     (rx_intf_tb.rx),
        .rx_data(rx_intf_tb.rx_data),
        .rx_done(rx_intf_tb.rx_done)
    );

    baud_tick_gen dut1 (
        .clk(rx_intf_tb.clk),
        .rst(rx_intf_tb.rst),
        .o_tick(w_b_tick)
    );

    always #5 rx_intf_tb.clk = ~rx_intf_tb.clk;

    initial begin
        rx_intf_tb.clk = 0;
        env = new(rx_intf_tb);
        env.reset();
        env.run();
    end
endmodule