// Sahil: Main UART module
`define IDLE       1'b0
`define BUSY       1'b1

`define DATA_WIDTH 32

module UART 
// #(
    // parameter int IDLE       = 1'b0
    // parameter int BUSY       = 1'b1

    // parameter int DATA_WIDTH = 32
// )
(
    input  reset,
    input  clk,
    input  [`DATA_WIDTH-1:0] TxData,
    input  TxReq,
    input  Rx,
    output reg Tx,
    output reg TxBusy,
    output reg [`DATA_WIDTH-1:0] RxData
);
    // We need a start and stop bit, first we will try with just 1 bit. 
    // So, a reset will set the Tx line to 1 and 0 would be the start bit.
    // the module would automatically stop after reading 32 bits, so no need for a stop bit.

    // Why is reset active low?
    // Multiple reasons stated:
    // 1. Better noise immunity.
    // 2. When power rails are coming up, signals can float and an active low signal defaults to low state as it uses a 
    // pull up resistor and everything would be in reset until stable conditions are reached.
    // 3. Reset is highly loaded(shared among many modules/peripherals), so there are no conflicts, anyone pulling low wins.

    // Declarations
    // FSM
    reg next_state_tx;
    reg next_state_rx;

    reg cur_state_tx;
    reg cur_state_rx;
    

    reg rx_busy;
    reg [32:0] padded_tx_data;

    integer transmit_count = 0;
    integer receive_count  = 0;

    // For Tx, once the request for tx is received, send start bit, convert parallel to serial and send the data.
    // transmitter FSM
    always @ (posedge clk, reset) begin
        // If reset is asserted, go back to IDLE state
        if (!reset) begin
            cur_state_tx <= `IDLE;
        // Else transition to the next state
        end else begin
            cur_state_tx <= next_state_tx;
        end
    end
        
    always_comb begin : NextTxFSM
        padded_tx_data = {1'b0, TxData};
        if(TxReq | TxBusy) begin
            TxBusy         = 1'b1;
            next_state_tx  = `BUSY;
            if(transmit_count == 0) begin
                TxBusy <= 1'b0;
            end
        end else begin
            next_state_tx  = `IDLE;
            TxBusy         = 1'b0;
        end
    end

    always @(posedge clk, reset) begin : Transmit
        if(reset == 1'b0) begin
            Tx             <= 1'b1;
            padded_tx_data <= 33'b0;
            transmit_count <= `DATA_WIDTH + 1;
        end else begin // if(reset == 1'b1)
            if(TxBusy == 1'b1) begin
                Tx             <= padded_tx_data[transmit_count-1];
                transmit_count <= transmit_count - 1;
            end else begin
                transmit_count <= `DATA_WIDTH + 1;
            end
        end
    end

    // For Rx, poll for the start bit and sample the data. As I'm fixing the bit length, we will sample for 32 bits and then stop until start bit is sensed again.
    // Receiver FSM
    always @ (posedge clk, reset) begin
        // If reset is asserted, go back to IDLE state
        if (!reset) begin
            cur_state_rx <= `IDLE;
        // Else transition to the next state
        end else begin
            cur_state_rx <= next_state_rx;
        end
    end

    always_comb begin : NextRXFSM
        if(!Rx | rx_busy) begin
            next_state_rx = `BUSY;
            rx_busy       = 1'b1;
            if(receive_count == 0) begin
                rx_busy = 1'b0;
            end
        end else begin
            next_state_rx = `IDLE;
            rx_busy       = 1'b0;
        end

    end

    always @(posedge clk, reset) begin
        if(!reset) begin
            RxData        <= 32'b0;
            receive_count <= `DATA_WIDTH;
        end else begin
            if(cur_state_rx == `BUSY) begin
                RxData[receive_count-1] <= Rx;
                receive_count <= receive_count - 1;
            end else begin
                receive_count <= `DATA_WIDTH;
            end
        end
    end

endmodule