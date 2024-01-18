// states of state machine
`define IDLE            4'b000
`define START_BIT       4'b001
`define DATA_BITS       4'b010
`define STOP_BIT        4'b011
`define RECEIVING_DATA  4'b100

`define BAUD_RATE   9600
`define CLOCK_RATE  5000000