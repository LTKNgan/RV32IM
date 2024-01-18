`include "UartStates.v"

/*
module old_Transmitter
(
    input  wire       baudClk, SYS_reset,    // baud rate
    input  wire [7:0] data_fromMem,           // data to transmit
    input             data_valid,
    output            request,
    output reg        tx, txDone          // tx
);
    reg [2:0] state  = `IDLE;
    reg [7:0] data   = 8'b0; // to store a copy of input data
    reg [2:0] bitIdx = 3'b0; // for 8-bit data

    assign request = (state == `IDLE) && txEn;

    always @(posedge baudClk) begin
        if (SYS_reset) begin
            state <= `IDLE;
            data <= 8'b0;
            bitIdx <= 3'b0;
            tx <= 1'b1;
            txDone <= 1'b0;
        end 
        else begin
            case (state)
                `IDLE: 
                begin
                    bitIdx <= 3'b0;
                    tx <= 1'b1; // drive line high for idle
                    if (data_valid ) 
                    begin
                        data <= data_fromMem; // save a copy of input data
                        txDone <= 1'b1;
                        state <= `START_BIT;
                    end 
                    else 
                    begin
                        data <= 8'b0;
                        txDone <= 1'b0;
                        state <= `IDLE;                    
                    end
                    
                end
                `START_BIT: begin
                    tx <= 1'b0; // send start bit (low)
                    txDone <= 1'b0;
                    state <= `DATA_BITS;
                end
                `DATA_BITS: begin // Wait 8 clock cycles for data bits to be sent
                    tx <= data[bitIdx];
                    if (&bitIdx) begin
                        bitIdx <= 3'b0;
                        state <= `STOP_BIT;
                    end else begin
                        bitIdx <= bitIdx + 1'b1;
                    end
                end
                `STOP_BIT: 
                begin // Send out Stop bit (high)
                    data <= 8'b0;
                    state <= `IDLE;
                    tx <= 1'b1;
                end

                default: 
                begin
                    state <= `IDLE;
                end
            endcase
        end
    end
endmodule
*/

module Transmitter
(
    input       clk, 
    input       SYS_reset,
    input       buffer_empty,    // baud rate
    input [7:0] data_in,           // data to transmit
    input       data_valid,

    output reg  data_requesting,
    output reg  tx,
    output reg  txDone          // tx
);
    reg [3:0] state  = `IDLE;
    reg [7:0] data   = 8'b0; // to store a copy of input data
    reg [2:0] bitIdx = 3'b0; // for 8-bit data

    // parameter MAX_RATE_TX = `CLOCK_RATE / `BAUD_RATE;
    parameter MAX_RATE_TX = (`CLOCK_RATE / `BAUD_RATE) - 1;
    parameter TX_CNT_WIDTH = $clog2(MAX_RATE_TX);

    reg [TX_CNT_WIDTH - 1:0] txCounter;

    // assign data_requesting = (state == `IDLE); // if the state = IDLE, we request the data7

    always @(posedge clk) 
    begin
        if (SYS_reset) 
        begin
            state     <= `IDLE;
            data      <= 8'b0;
            bitIdx    <= 3'b0;
            tx        <= 1'b1;
            txDone    <= 1'b0;
            txCounter <= 0;
            data_requesting <= 0;
        end

        else 
        begin
            case (state)
                `IDLE: 
                begin
                    bitIdx <= 3'b0;
                    tx <= 1'b1; // drive line high for idle
                    txCounter <= 0;

                    if (data_requesting) 
                    begin
                        data_requesting <= 0;
                        data <= 8'b0; 
                        txDone <= 1'b1;
                        state <= `RECEIVING_DATA;
                    end 
                    else //not sent
                    begin
                        if (!buffer_empty)
                            data_requesting <= 1;
                        else
                            data_requesting <= 0;
                        data <= 8'b0;
                        txDone <= 1'b0;
                        state <= `IDLE;                    
                    end 
                end

                `RECEIVING_DATA:
                begin
                    data <= data_in;
                    state <= `START_BIT;
                end

                `START_BIT: 
                begin
                    txDone <= 1'b0; 
                    if (txCounter >= MAX_RATE_TX) 
                    begin
                        txCounter <= 0;
                        tx <= 1'b0; // send start bit (low)
                        state <= `DATA_BITS;
                    end 

                    else txCounter <= txCounter + 1'b1;
                end

                `DATA_BITS: 
                begin // Wait 8 clock cycles for data bits to be sent
                    if (txCounter >= MAX_RATE_TX) 
                    begin
                        txCounter <= 0;
                        tx <= data[bitIdx];

                        if (&bitIdx) 
                        begin
                            bitIdx <= 3'b0;
                            state <= `STOP_BIT;
                        end 

                        else 
                        begin
                            bitIdx <= bitIdx + 1'b1;
                        end
                    end 

                    else txCounter <= txCounter + 1'b1;
                        
                end

                `STOP_BIT: 
                begin // Send out Stop bit (high)
                    if (txCounter >= MAX_RATE_TX) 
                    begin
                        txCounter <= 0;
                        data <= 8'b0;
                        state <= `IDLE;
                        tx <= 1'b1;
                    end

                    else txCounter <= txCounter + 1'b1;
                end

                default: 
                begin
                    state <= `IDLE;
                end
            endcase
        end
    end
endmodule