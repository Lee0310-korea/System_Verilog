`timescale 1ns / 1ps

module TOP_I2C (
    input logic       clk,
    input logic       reset,
    input logic [7:0] m_tx_data,
    input logic       m_tx_done,
    input logic       m_tx_ready,
    input logic [7:0] m_rx_data,
    input logic       m_rx_done,
    input logic [7:0] s_tx_data,
    input logic       s_tx_done,
    input logic       s_tx_ready,
    input logic [7:0] s_rx_data,
    input logic       s_rx_done
);

    // global ports
    logic                      I2C_En;
    logic [               6:0] addr;
    logic                      CR_RW;
    logic                      I2C_start;
    logic                      I2C_stop;
    logic [$clog2(D_LENGTH):0] length;
    logic                      SCL;
    logic                      SDA;
    // External signals
    I2C_MASTER dut_master (
        .*,
        // internal ports
        .I2C_En   (I2C_En),
        .addr     (addr),
        .CR_RW    (CR_RW),
        .tx_data  (m_tx_data),
        .tx_done  (m_tx_done),
        .tx_ready (m_tx_ready),
        .rx_data  (m_rx_data),
        .rx_done  (m_rx_done),
        .I2C_start(I2C_start),
        .I2C_stop (I2C_stop),
        .length   (length)
    );

    I2C_SLAVE dut_slave (
        .*,
        .tx_data (s_tx_data),
        .tx_done (s_tx_done),
        .tx_ready(s_tx_ready),
        .rx_data (s_rx_data),
        .rx_done (s_rx_done),
        .scl     (SCL),
        .sda     (SDA)
    );

endmodule
