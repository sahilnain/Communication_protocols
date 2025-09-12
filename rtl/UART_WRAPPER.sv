// Sahil: A wrapper for the UART, here I instantiate 2 UART modules and connect them together.
`define DATA_BITS 32

module UART_WRAPPER (
    input  reset,
    input  clk,
    // Parameters for B
    input  [`DATA_BITS-1:0] TxData_A,
    input  TxReq_A,
    input  Rx_A,
    output reg Tx_A,
    output reg TxBusy_A,
    output reg [`DATA_BITS-1:0] RxData_A,
    // Parameters for B
    input  [`DATA_BITS-1:0] TxData_B,
    input  TxReq_B,
    input  Rx_B,
    output reg Tx_B,
    output reg TxBusy_B,
    output reg [`DATA_BITS-1:0] RxData_B
);

    // Wires
    wire A_2_B;
    wire B_2_A;

    UART uart_A (
        .reset(reset),
        .clk(clk),
        .TxData(TxData_A),
        .TxReq(TxReq_A),
        .Rx(B_2_A),
        .Tx(A_2_B),
        .TxBusy(TxBusy_A),
        .RxData(RxData_A)
    );

    UART uart_B (
        .reset(reset),
        .clk(clk),
        .TxData(TxData_B),
        .TxReq(TxReq_B),
        .Rx(A_2_B),
        .Tx(B_2_A),
        .TxBusy(TxBusy_B),
        .RxData(RxData_B)
    );
endmodule