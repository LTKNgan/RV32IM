`include "include.v"


/*
 * read pointer: con tro doc o clock tiep theo 
 * writer pointer: con tro ghi o clock tiep theo
 */

module fifo_buffer // SYS_reset from button
(
    input       clk, SYS_reset,
    input       write_request,  // signal from controller
    input[7:0]  data_in, 
    input       read_request, //yêu cầu một data mới
    // input       read_done,

    output reg  full, 
    output reg  empty,        // use for enable read and write 

    output reg  data_valid,
    output reg [7:0] data_out  

);
    reg  [7:0] mem[0:31];  
    reg  [4:0] write_pointer, read_pointer;       // read, write pointer  of memory

    integer i;
    always @(posedge clk)  
    begin  
        if(SYS_reset)
        begin
            write_pointer <= 0;  
            full          <= 0;
            empty         <= 1;
            read_pointer  <= 0;
            data_valid    <= 0;
            data_out      <= 0;
            for (i = 0; i <= 31; i = i + 1) 
                mem[i] <= 0;
        end

        else
        begin
            if (write_request)
            begin
                if (!full) 
                begin
                    mem[write_pointer] <= data_in;
                    write_pointer      <= write_pointer + 1;
                    empty              <= 0;
                    if ((write_pointer + 1 == read_pointer) || (write_pointer == 31 && read_pointer == 0))
                        full <= 1;
                end
            end

            if (read_request)
            begin
                if (!empty)
                begin
                    data_out     <= mem[read_pointer];
                    data_valid   <= 1;
                    read_pointer <= read_pointer + 1;
                    full         <= 0;
                    if ((read_pointer + 1 == write_pointer) || (read_pointer == 31 && write_pointer == 0))
                        empty <= 1;
                end
    
                else //if empty
                    data_valid <= 0;
            end
            
            else //if no read_request
                data_valid <= 0;
        end
    end
endmodule