// Sahil: A wrapper for the UART, here I instantiate 2 UART modules and connect them together.
`define DATA_BITS 32

module UART_WRAPPER (
    input  reset,
    input  clk,
    input  [`DATA_BITS-1:0] TxData,
    input  TxReq,
    input  Rx,
    output reg Tx,
    output reg TxBusy,
    output reg [`DATA_BITS-1:0] RxData
);

    // Wires
    wire A_2_B;
    wire B_2_A;

    UART uart_A (
        .reset(reset),
        .clk(clk),
        .TxData(TxData),
        .TxReq(TxReq),
        .Rx(B_2_A),
        .Tx(A_2_B),
        .TxBusy(TxBusy),
        .RxData()
    );

    UART uart_B (
        .reset(reset),
        .clk(clk),
        .TxData(TxData),
        .TxReq(1'b0),
        .Rx(A_2_B),
        .Tx(B_2_A),
        .TxBusy(),
        .RxData(RxData)
    );
endmodule