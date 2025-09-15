// Sahil: Main UART module
`define FSM_WIDTH  2
`define IDLE       2'b00
`define LOAD       2'b01
`define START      2'b10
`define BUSY       2'b11

`define COUNTER_WIDTH 6
`define DATA_WIDTH    32

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
    reg tx_start;
    wire tx_bit;
    reg load_data_tx;
    reg serial_out_en;
    wire [`COUNTER_WIDTH-1:0] tx_count;
    reg left_right_shift;

    reg rx_start;
    reg get_rx_data;
    wire [`DATA_WIDTH-1:0] parallel_out;
    wire [`COUNTER_WIDTH-1:0] rx_count;

    // FSM
    reg [`FSM_WIDTH-1:0] cur_state_tx;
    reg [`FSM_WIDTH-1:0] next_state_tx;

    reg [`FSM_WIDTH-1:0] next_state_rx;
    reg [`FSM_WIDTH-1:0] cur_state_rx;
    
    // Module instances
    UpDown_counter #( .WIDTH(`COUNTER_WIDTH) ) tx_counter //6 bit counter
    (
        .reset (reset),
        .clk   (clk),
        .enable(tx_start),
        .upDown(1'b1), // up_counter
        .count (tx_count)
    );

    UpDown_counter #( .WIDTH(`COUNTER_WIDTH) ) rx_counter //6 bit counter
    (
        .reset (reset),
        .clk   (clk),
        .enable(rx_start),
        .upDown(1'b1), // up_counter
        .count (rx_count)
    );

    ShiftReg #( .WIDTH(`DATA_WIDTH) ) shift_reg// 32 bit register
    (
        .reset(reset),
        .clk(clk),
        .load(load_data_tx),
        .serialOutEn(serial_out_en),
        .leftRight(left_right_shift), // left_shift
        .parallelOutEn(get_rx_data),
        .serialIn(Rx),
        .parallelIn({1'b0, TxData}),
        .serialOut(Tx),
        .parallelOut(parallel_out)
    );

    // For Tx, once the request for tx is received, send start bit, convert parallel to serial and send the data.
    always @ (posedge clk or negedge reset) begin : txStateUpdate
        // If reset is asserted, go back to IDLE state
        if (!reset) begin
            cur_state_tx <= `IDLE;
        // Else transition to the next state
        end else begin
            cur_state_tx <= next_state_tx;
        end
    end

    always_comb begin : txFSMLogic
        case (cur_state_tx)
            `IDLE: begin
                tx_start      = 1'b0;
                serial_out_en = 1'b0;
                if(TxReq) begin
                    load_data_tx  = 1'b1;
                    next_state_tx = `LOAD;
                end else begin
                    load_data_tx  = 1'b0;
                    next_state_tx = `IDLE;
                end
            end
            `LOAD: begin
                tx_start      = 1'b0;
                load_data_tx  = 1'b0;
                serial_out_en = 1'b0;
                next_state_tx = `START;
            end
            `START: begin
                tx_start      = 1'b1;
                TxBusy        = 1'b1;
                load_data_tx  = 1'b0;
                serial_out_en = 1'b1;
                next_state_tx = `BUSY;
            end
            `BUSY: begin
                load_data_tx  = 1'b0;
                serial_out_en = 1'b1;
                TxBusy        = 1'b1;
                tx_start      = 1'b1;
                if(tx_count == `DATA_WIDTH) begin
                    next_state_tx = `IDLE;
                end else begin
                    next_state_tx = `BUSY;
                end
            end
            default: begin
                tx_start      = 1'b0;
                load_data_tx  = 1'b0;
                next_state_tx = `IDLE;
                serial_out_en = 1'b0;
            end
        endcase
    end

    // For Rx, poll for the start bit and sample the data. As I'm fixing the bit length, we will sample for 32 bits and then stop until start bit is sensed again.
    // Receiver FSM
    always @ (posedge clk or negedge reset) begin
        // If reset is asserted, go back to IDLE state
        if (!reset) begin
            cur_state_rx <= `IDLE;
        // Else transition to the next state
        end else begin
            cur_state_rx <= next_state_rx;
        end
    end

    always_comb begin : rxFSMLogic
        case (cur_state_rx)
            `IDLE: begin
                get_rx_data   = 1'b0;
                rx_start      = 1'b0;
                next_state_rx = `IDLE;
                if(!Rx) begin
                    get_rx_data   = 1'b1;
                    rx_start      = 1'b1;
                    next_state_rx = `BUSY;
                end
            end
            `BUSY: begin
                get_rx_data   = 1'b1;
                rx_start      = 1'b1;
                if(rx_count == `DATA_WIDTH) begin
                    next_state_rx = `IDLE;
                end else begin
                    next_state_rx = `BUSY;
                end
            end
            default: begin
                get_rx_data   = 1'b0;
                rx_start      = 1'b0;
                next_state_rx = `IDLE;
            end
        endcase
    end

    always @ (posedge clk or negedge reset) begin
        if (!reset)
            RxData <= '0;
        else
            RxData <= parallel_out;
    end

    always @ (posedge clk or negedge reset) begin
        if (!reset)
            left_right_shift <= '0;
        else
            left_right_shift <= 1'b1;
    end
    
endmodule