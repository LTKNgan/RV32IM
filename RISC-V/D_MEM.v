`include "include.v"

module DATA_MEMORY
(
    input wire [0:0]  clk,
    input wire [0:0]  SYS_reset,

    input wire [1:0]  MEM_read_length,
    input wire        MEM_read_signed,

    input wire [1:0]  MEM_write_length,
    input wire [31:0] MEM_write_data,
    input wire [31:0] MEM_write_address,

    input wire [31:0] MEM_read_address,

    input             CPU_finish_execution, 
    input             transmitter_buffer_full,

    input             CPU_execute_enable,
    input             data_to_CPU_valid,
    input     [7:0]   data_to_CPU,

    output            DMEM_transmit_request,
    output      [7:0] DMEM_data_transmit,
    output reg [31:0] DMEM_transmit_address,

    output reg [31:0] MEM_read_data
);
    reg [7:0] data [`DATA_START_ADDRESS :`DATA_END_ADDRESS];
    reg [31:0]initialize_address;

    assign DMEM_data_transmit    = data [DMEM_transmit_address];
    assign DMEM_transmit_request = CPU_finish_execution && (`DATA_START_ADDRESS <= DMEM_transmit_address) && (DMEM_transmit_address <= `DATA_END_ADDRESS);

    always @(*) 
    begin
        MEM_read_data[31:0]   = {data[MEM_read_address+0],data[MEM_read_address+1], data[MEM_read_address+2], data[MEM_read_address+3]};
        
        if (MEM_read_length == 2'b01) //read 1 byte
        begin
            if (MEM_read_signed)
                MEM_read_data = { {24{data[MEM_read_address][7]}}  , data[MEM_read_address]};
            else 
                MEM_read_data = { {24{1'b0}}  , data[MEM_read_address]};
        end

        else if (MEM_read_length == 2'b10) //read half word
        begin
            if (MEM_read_signed)
                MEM_read_data = { {16{data[MEM_read_address + 0][7]}}  , data[MEM_read_address+0], data[MEM_read_address+1]};
            else 
                MEM_read_data = { {16{1'b0}}  ,                          data[MEM_read_address+0], data[MEM_read_address+1]};
        end
    end

    integer i, file;
    always @(posedge clk) 
    begin
        if (SYS_reset)
        begin
            initialize_address <= `DATA_START_ADDRESS;

            for (i = `DATA_START_ADDRESS ; i <=`DATA_END_ADDRESS; i = i + 1)
                data [i] = 0;
        end

        else if (CPU_execute_enable == 0)
        begin
            if (data_to_CPU_valid && (initialize_address <= `DATA_END_ADDRESS) )
            begin
                data[initialize_address] <= data_to_CPU;
                initialize_address       <= initialize_address + 1;
            end
        end

        else if (MEM_write_length == 2'b01) //store 1 byte
        begin
            data[MEM_write_address+0] <= MEM_write_data[7:0];
        end

        else if (MEM_write_length == 2'b10) //store half-word
        begin
            data[MEM_write_address  ] <= MEM_write_data[15:8];
            data[MEM_write_address+1] <= MEM_write_data[7:0];
        end

        else if (MEM_write_length == 2'b11) //store word
        begin
            data[MEM_write_address  ] <= MEM_write_data[31:24];
            data[MEM_write_address+1] <= MEM_write_data[23:16];
            data[MEM_write_address+2] <= MEM_write_data[15:8];
            data[MEM_write_address+3] <= MEM_write_data[7:0];
        end
    end

    always @(posedge clk) 
    begin
        if       (SYS_reset)
            DMEM_transmit_address <= `DATA_START_ADDRESS;

        else if ((DMEM_transmit_request) && (!transmitter_buffer_full))
            DMEM_transmit_address <= DMEM_transmit_address + 1;
    end

endmodule