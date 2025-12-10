`timescale 1ns / 1ps

parameter BAUD_RATE = 9600;
    parameter CLOCK_PERIOD_NS = 10;  //100Mhz
    parameter BITPERCLOCK = 100_000_000 / BAUD_RATE; //10416;  // 1 / BAUD_RATE;  // 1bit per clock 1/9600
    parameter BIT_PERIOD =BITPERCLOCK * CLOCK_PERIOD_NS;  //number of clock * 10ns

interface UART_TOP_intf;
    logic clk;
    logic rst;
    logic rx;
    logic [7:0] rx_data;
    logic tx;
    logic [7:0] tx_data;

endinterface

class transaction;
    bit rx;
    rand bit [7:0] rx_data;
    bit tx;
    bit [7:0] tx_data;

    task display(string name_s);
        $display("%t [%s] 8bit_rx_data = %d ", $time, name_s, rx_data);
    endtask  //
endclass  //transaction

class generator;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_event;
    virtual UART_TOP_intf uart_intf;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_event);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int count);
        repeat (count) begin
            tr = new();
            assert (tr.randomize())
            else $display("[GEN] tr.randomize() error!");
            gen2drv_mbox.put(tr);
            tr.display("trans");
            $display("%t GEN",$time);
            @(gen_next_event);
        end
    endtask  //
endclass

class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_event;
    virtual UART_TOP_intf uart_intf;

    function new(mailbox#(transaction) gen2drv_mbox, virtual UART_TOP_intf uart_intf,
                 event gen_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.uart_intf = uart_intf;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task reset();
        uart_intf.clk = 0;
        uart_intf.rst = 1;
        uart_intf.rx  = 1;
        @(posedge uart_intf.clk);
        uart_intf.rst = 0;
    endtask  //

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            uart_intf.rx_data = tr.rx_data;
            uart_intf.rx = 1;
            #(BIT_PERIOD);
            uart_intf.rx = 0;
            #(BIT_PERIOD);
            for (int i = 0; i < 8; i++) begin
                uart_intf.rx = tr.rx_data[i];
                #(BIT_PERIOD);
            end
            uart_intf.rx = 1;
            tr.display("[DRV]");
            @(posedge uart_intf.clk);
            ->gen_next_event;  // 
        end
    endtask  //
endclass  //driver

class environment;

    mailbox #(transaction) gen2drv_mbox;
    event gen_next_event;
    generator gen;
    driver drv;

    function new(virtual UART_TOP_intf uart_intf);
        gen2drv_mbox = new();
        gen = new(gen2drv_mbox, gen_next_event);
        drv = new(gen2drv_mbox, uart_intf, gen_next_event);
    endfunction  //new()
    task  reset();
                drv.reset();
    endtask //
    task run();
        fork
            gen.run(10);
            drv.run();
        join_any
        $display("ENV");
        $stop;
    endtask  //

endclass  //environment

module tb_uart_top ();

    UART_TOP_intf uart_intf_tb ();
    environment env;

    UART_TOP UUT (
        .clk(uart_intf_tb.clk),
        .rst(uart_intf_tb.rst),
        .rx (uart_intf_tb.rx),
        .tx (uart_intf_tb.tx)
    );

    assign #5 uart_intf_tb.clk = ~uart_intf_tb.clk;

    initial begin
        env = new(uart_intf_tb);
        env.reset();
        env.run();
    end
endmodule
