`include "UartStates.v"
module Receiver
(
    input       clk, 
    input       SYS_reset,    // baud rate
    input       rx,
    output reg  [7:0] data_out,          // received data
    output reg  rxDone                // end on transaction
);
    reg [3:0] state;
    reg [2:0] bitIdx;        // for 8-bit data
    reg [1:0] inputSw;       // shift reg for input signal state
    reg [3:0] clockCount;    // count clocks for 16x oversample
    reg [7:0] receivedData;  // temporary storage for input data

    // parameter MAX_RATE_RX = `CLOCK_RATE / (`BAUD_RATE * 16); // 16x oversampling
    parameter MAX_RATE_RX = (`CLOCK_RATE / (`BAUD_RATE * 16)) - 1; // 16x oversampling
    parameter RX_CNT_WIDTH = $clog2(MAX_RATE_RX);
    reg [RX_CNT_WIDTH - 1:0] rxCounter;

    always @(posedge clk) begin
        if (SYS_reset) 
        begin
            state <= `IDLE;
            bitIdx <= 3'b0;
            clockCount <= 4'b0;
            receivedData <= 8'b0;
            data_out <= 8'b0;
            rxDone <= 1'b0;
            inputSw <= 2'b0;
            rxCounter <= 0;
        end
        
        else 
        begin
            inputSw <= { inputSw[0], rx };   // shift bit
            case (state)
                `IDLE: 
                begin
                    bitIdx <= 3'b0;
                    clockCount <= 4'b0;
                    receivedData <= 8'b0;
                    data_out <= 8'b0;
                    rxDone <= 1'b0;
                    rxCounter <= 0;
                    if (~rx) state <= `START_BIT;
                end
                // Wait 8 full cycles to receive serial data
                `START_BIT: begin
                    if (rxCounter >= MAX_RATE_RX) begin
                        rxCounter <= 0;
                        if (&clockCount[2:0]) begin
                            state <= `DATA_BITS;
                            clockCount <= 0;
                        end else clockCount <= clockCount + 4'b1;
                    end else rxCounter <= rxCounter + 1'b1;
                end
    
                `DATA_BITS: 
                begin
                    if (rxCounter >= MAX_RATE_RX) begin
                        rxCounter <= 0;
                        if (&clockCount) begin // save one bit of received data
                            clockCount <= 4'b0;
                            receivedData[bitIdx] <= inputSw[0]; // little edian
                            if (&bitIdx) begin
                                bitIdx <= 3'b0;
                                state <= `STOP_BIT;
                            end else begin
                                bitIdx <= bitIdx + 3'b1;
                            end
                        end else begin
                            clockCount <= clockCount + 4'b1;
                        end
                    end else rxCounter <= rxCounter + 1'b1;
                end
    
                `STOP_BIT: 
                begin
                    if (rxCounter >= MAX_RATE_RX) begin
                        rxCounter <= 0;
                        if (&clockCount) begin      // receive stop bit
                            rxDone <= 1'b1;
                            state <= `IDLE;
                            clockCount <= 4'b0;
                            data_out <= receivedData;
                        end else begin
                            clockCount <= clockCount + 1;
                        end
                    end else rxCounter <= rxCounter + 1'b1;
                end

                default: 
                begin
                    state <= `IDLE;
                end
            endcase
        end
    end
endmodule
