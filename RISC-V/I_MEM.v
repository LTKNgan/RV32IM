`include "include.v"
module INS_MEMORY
(
    input wire [0:0] clk,
    input wire [0:0] SYS_reset,
    input            SYS_start_button,
    input  wire [31:0]  PC,

    input      inst_to_CPU_valid,
    input[7:0] inst_to_CPU,  

    output reg          CPU_execute_enable,
    output wire [31:0]  instruction
);
    reg [7:0] data [(`INS_START_ADDRESS) : (`INS_START_ADDRESS) + 1000];

    reg [31:0] initialize_address;

    assign instruction[31:0] = {data[PC], data[PC+1], data[PC+2], data[PC+3]};

    integer i, file;
    always @(posedge clk) 
    begin
        if (SYS_reset)
        begin
            for(i=`INS_START_ADDRESS; i<`INS_START_ADDRESS + 1000 ;i=i+1)
            begin
                data[i] <= 0;
            end

            CPU_execute_enable <= 0;
            initialize_address<= `INS_START_ADDRESS;

            `ifdef TESTING
            $readmemh("C:/Users/tuankiet/Desktop/RISC-V/test/input_text.txt", data);
            `endif
        end

        else if (SYS_start_button)
            CPU_execute_enable <= 1;

        else if (CPU_execute_enable == 0)
        begin
            if (inst_to_CPU_valid)
            begin
                data[initialize_address] <= inst_to_CPU;
                initialize_address       <= initialize_address + 1;
            end     


        end
    end

endmodule