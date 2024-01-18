`include "include.v"


module RISCV_CPU
(
    input             clk,
    input             SYS_reset,
    input             SYS_start_button,
    input             terminate_interrupt_button,

    input             inst_to_CPU_valid,
    input     [7:0]   inst_to_CPU,
    input             data_to_CPU_valid,
    input     [7:0]   data_to_CPU,
    input             transmitter_buffer_full,
    
    output            DMEM_transmit_request,
    output      [7:0] DMEM_data_transmit,
    output     [31:0] DMEM_transmit_address,
    output            CPU_execute_enable,
    output            CPU_finish_execution
);

    reg  [31:0] PC;
    reg         terminate_interrupt;

    wire [0:0] invalid_instruction;
    wire [31:0]instruction;
    wire [31:0]new_PC; //need to choose

    wire [1:0]  MEM_write_length;
    wire [1:0]  MEM_read_length;
    wire        MEM_read_signed;
    wire [31:0] MEM_write_data;
    wire [31:0] MEM_write_address;
    wire [31:0] MEM_read_address;
    wire [31:0] MEM_read_data;

    wire [4:0] rs1, rs2, REG_write_address;
    wire [0:0] REG_write_enable;
    wire [31:0]REG_write_value, REG_rs1_data, REG_rs2_data;

    assign     CPU_finish_execution = CPU_execute_enable && (invalid_instruction || terminate_interrupt);

    always @(posedge clk)
    begin
        if (SYS_reset)
        begin
            PC <= `INS_START_ADDRESS;
            terminate_interrupt <= 0;
        end
        
        else 
        begin
            PC <= new_PC;

            if (CPU_execute_enable && terminate_interrupt_button) terminate_interrupt <= 1;
        end

    end

    DATA_MEMORY DMEM //the block hold the insrtuciton and data. It can be read every time and written at the clock. once
    (
        .clk                     (clk),
        .SYS_reset               (SYS_reset),
        //INPUT
        .MEM_write_length        (MEM_write_length),
        .MEM_read_length         (MEM_read_length),
        .MEM_read_signed         (MEM_read_signed),
        .MEM_write_data          (MEM_write_data),
        .MEM_write_address       (MEM_write_address),
        .MEM_read_address        (MEM_read_address),
        .CPU_finish_execution    (CPU_finish_execution),
        .transmitter_buffer_full (transmitter_buffer_full),
        .data_to_CPU_valid       (data_to_CPU_valid),
        .data_to_CPU             (data_to_CPU),
        .CPU_execute_enable      (CPU_execute_enable),

        //OUTPUT
        .DMEM_transmit_request   (DMEM_transmit_request),
        .DMEM_data_transmit      (DMEM_data_transmit),
        .DMEM_transmit_address   (DMEM_transmit_address),
        .MEM_read_data           (MEM_read_data)
    );
    
    INS_MEMORY  IMEM
    (
        //INPUT
        .clk                (clk),
        .SYS_reset          (SYS_reset),
        .SYS_start_button   (SYS_start_button),
        .PC                 (PC),  
        .inst_to_CPU_valid (inst_to_CPU_valid),
        .inst_to_CPU       (inst_to_CPU),

        //OUTPUT
        .instruction        (instruction), //got the instruction
        .CPU_execute_enable (CPU_execute_enable)
    );




    REGISTER_FILE register_file
    (
        .clk            (clk),
        .SYS_reset          (SYS_reset),
        .rs1                (rs1),
        .rs2                (rs2), 
        .REG_write_address  (REG_write_address), //written value may rd or else
        .REG_write_enable   (REG_write_enable), 
        .REG_write_value    (REG_write_value), 


        .REG_rs1_data       (REG_rs1_data), 
        .REG_rs2_data       (REG_rs2_data)

    );

    DATA_PATH DATA_PATH
    (
        //INPUT
        .instruction        (instruction),
        .REG_rs1_data       (REG_rs1_data),
        .REG_rs2_data       (REG_rs2_data),
        .MEM_read_data      (MEM_read_data),
        .PC                 (PC),
        .CPU_execute_enable (CPU_execute_enable),

        //OUTPUT
        .new_PC             (new_PC),
        .REG_write_value    (REG_write_value),
        .REG_write_enable   (REG_write_enable),
        .REG_write_address  (REG_write_address),

        .MEM_write_length   (MEM_write_length),
        .MEM_read_length    (MEM_read_length),
        .MEM_read_signed    (MEM_read_signed),
        .MEM_write_data     (MEM_write_data),
        .MEM_write_address  (MEM_write_address),

        .MEM_read_address   (MEM_read_address),
        .invalid_instruction(invalid_instruction),

        .rs1                (rs1),
        .rs2                (rs2)
    );
endmodule


module DATA_PATH
(
    input        terminate_interrupt,
    input [31:0] instruction,
    input [31:0] REG_rs1_data,
    input [31:0] REG_rs2_data,
    input [31:0] MEM_read_data,
    input [31:0] PC,
    input        CPU_execute_enable,

    output reg [31:0] new_PC,
    output reg [31:0] REG_write_value,
    output reg [0:0]  REG_write_enable,
    output reg [4:0]  REG_write_address,
    
    output reg [1:0]  MEM_write_length,
    output reg [1:0]  MEM_read_length,
    output reg        MEM_read_signed,
    output reg [31:0] MEM_write_data,
    output reg [31:0] MEM_write_address,

    output reg [31:0] MEM_read_address,
    output reg [0:0]  invalid_instruction,
    output wire [4:0] rs1,
    output wire [4:0] rs2
);
    wire [6:0] opcode   = instruction [6:0];
    wire [4:0] rd       = instruction [11:7];
    assign     rs1      = instruction [19:15];
    assign     rs2      = instruction [24:20];
    wire [4:0] shamt    = instruction [24:20];
    wire [2:0] funct3   = instruction [14:12];
    wire [6:0] funct7   = instruction [31:25]; //R-type only
    wire [11:0]S_immed  ={instruction[31:25], instruction[11:7]}; //S-type only, for STORE
    wire [11:0]I_immed  = instruction[31:20];//I-type only, for LOAD and immediate ADD SUB....
    wire [12:1]B_immed  ={instruction[31], instruction[7], instruction[30:25], instruction[11:8]}; //B-type only, for conditional BRANCH
    wire [20:1]J_immed  ={instruction[31], instruction[19:12], instruction[20], instruction[30:21]};//J-type only, for JUMP-AND-LINK
    wire[31:12]U_immed  = instruction[31:12]; //U_type only, for LUI, wide immediate instruction....

    reg branch_taken;

    always @(terminate_interrupt, instruction, opcode,rd,rs1,rs2,shamt,funct3,funct7,S_immed,I_immed, B_immed,J_immed,U_immed,   REG_rs1_data, REG_rs2_data, MEM_read_data, PC, CPU_execute_enable) // all the input
    begin
        //set the default, also prevent latch
        new_PC              = PC + 4;
        REG_write_value     = 0;
        REG_write_enable    = 0;
        REG_write_address   = 0;
        MEM_write_length    = 0;
        MEM_read_length     = 2'b11;
        MEM_read_signed     = 0;
        MEM_write_data      = 0;
        MEM_write_address   = 0;
        MEM_read_address    = 0;

        branch_taken        = 0;
        invalid_instruction = 0;

        case (opcode)
            7'b0110011: 
            begin //base-R, 10 instructions
                REG_write_enable = 1;
                REG_write_address= rd;

                //The funct7 and funct3 fields select the type of operation.
                case ({funct7, funct3})
                    10'b0000000_000: REG_write_value = REG_rs1_data + REG_rs2_data; //add
                    10'b0100000_000: REG_write_value = REG_rs1_data - REG_rs2_data;//sub
                    10'b0000000_001: REG_write_value = REG_rs1_data << REG_rs2_data;// ALU_operation = `ALU_SHIFT_LEFT;//sll
                    10'b0000000_010: REG_write_value = $signed(REG_rs1_data) < $signed(REG_rs2_data);  //ALU_operation = `ALU_LESS_SIGNED;//slt
                    10'b0000000_011: REG_write_value = $unsigned(REG_rs1_data) < $unsigned(REG_rs2_data);//sltu
                    10'b0000000_100: REG_write_value = REG_rs1_data ^ REG_rs2_data;//xor
                    10'b0000000_101: REG_write_value = REG_rs1_data >> REG_rs2_data;//srl
                    10'b0100000_101: REG_write_value = $signed(REG_rs1_data) >>> REG_rs2_data;//sra
                    10'b0000000_110: REG_write_value = REG_rs1_data | REG_rs2_data;//or
                    10'b0000000_111: REG_write_value = REG_rs1_data & REG_rs2_data;//and

                    10'b0000001_000: REG_write_value =  REG_rs1_data * REG_rs2_data;//mul, treat them as signed and put the LOWER in result
                    10'b0000001_001: REG_write_value = ({{32{REG_rs1_data[31]}} , REG_rs1_data} * {{32{REG_rs2_data[31]}} , REG_rs2_data}) >> 32;//mulh
                    10'b0000001_010: REG_write_value = ({{32{REG_rs1_data[31]}} , REG_rs1_data} * {{32{1'b0}}                , REG_rs2_data}) >> 32;//mulhsu
                    10'b0000001_011: REG_write_value = ({{32{1'b0}}                , REG_rs1_data} * {{32{1'b0}}                , REG_rs2_data}) >> 32;//mulhu
                    10'b0000001_100: REG_write_value = ($signed  (REG_rs1_data) / $signed   (REG_rs2_data));//div
                    10'b0000001_101: REG_write_value = ($unsigned(REG_rs1_data) / $unsigned (REG_rs2_data));//divu
                    10'b0000001_110: REG_write_value = ($signed  (REG_rs1_data) % $signed   (REG_rs2_data));//rem
                    10'b0000001_111: REG_write_value = ($unsigned(REG_rs1_data) % $unsigned (REG_rs2_data));//remu
                    default         : invalid_instruction = 1;
                endcase
            end

            7'b0110111: //LUI
            begin
                REG_write_enable = 1;
                REG_write_address= rd;
                // REG_write_value = { U_immed[31:12] , {12{0}} }; //replaced
                REG_write_value = instruction[31:12] << 12;
            end

            7'b0010111: //AUICPC
            begin
                REG_write_enable = 1;
                REG_write_address= rd;
                REG_write_value = PC + (instruction[31:12] << 12);
            end

            7'b0010011: //I- arthimetic and shift
            begin
                REG_write_enable = 1;
                REG_write_address= rd;

                case (funct3)
                    3'b000: REG_write_value = $signed(REG_rs1_data) + $signed({{20{I_immed[11]}} ,I_immed});
                    3'b010: REG_write_value = $signed(REG_rs1_data) < $signed({{20{I_immed[11]}} ,I_immed});
                    3'b011: REG_write_value = $unsigned(REG_rs1_data) < $unsigned({{20{1'b0}} ,I_immed});
                    3'b100: REG_write_value = $unsigned(REG_rs1_data) ^ $signed({{20{I_immed[11]}} ,I_immed});
                    3'b110: REG_write_value = $unsigned(REG_rs1_data) | $signed({{20{I_immed[11]}} ,I_immed});
                    3'b111: REG_write_value = $unsigned(REG_rs1_data) & $signed({{20{I_immed[11]}} ,I_immed});
                    3'b001: REG_write_value = REG_rs1_data << shamt;
                    3'b101: if (funct7 == 7'd0) 
                                REG_write_value = REG_rs1_data >> shamt;
                            else
                                REG_write_value = $signed(REG_rs1_data) >>> shamt;
                    default: invalid_instruction = 1;
                endcase
            end

            7'b0000011: //I - loads
            begin
                REG_write_enable = 1;
                REG_write_address= rd;

                case (funct3)
                    3'b010: MEM_read_length  = 2'b11; //lw
                    
                    3'b000: //lb
                    begin
                        MEM_read_length = 2'b01;
                        MEM_read_signed = 1;
                    end

                    3'b001: //lh
                    begin
                        MEM_read_length = 2'b10;
                        MEM_read_signed = 1;
                    end

                    3'b100: //lbu
                    begin
                        MEM_read_length = 2'b01;
                        MEM_read_signed = 0;
                    end

                    3'b101: //lhu
                    begin
                        MEM_read_length = 2'b10;
                        MEM_read_signed = 0;
                    end

                    default: MEM_read_length  = 2'b11;
                endcase

                MEM_read_address = REG_rs1_data + $signed({{20{I_immed[11]}} ,I_immed}); // go to change the mem read value...
                REG_write_value = MEM_read_data;
            end

            7'b0100011:
            begin
                case (funct3)
                    3'b000: MEM_write_length = 2'b01;

                    3'b001: MEM_write_length = 2'b10;

                    3'b010: MEM_write_length = 2'b11;

                    default: MEM_write_length = 0;
                endcase

                MEM_write_data      = REG_rs2_data;
                MEM_write_address   = REG_rs1_data + $signed({{20{S_immed[11]}} ,S_immed});
            end

            7'b1100111: //I- jalr only
            begin
                REG_write_enable = 1;
                REG_write_address= rd;
                REG_write_value  = PC + 4;
                new_PC           = (REG_rs1_data + $signed({{20{I_immed[11]}} ,I_immed})) & (32'hFFFF_FFFF - 1) ;
            end

            7'b1101111: // J jal only
            begin
                REG_write_enable = 1;
                REG_write_address= rd;
                REG_write_value  = PC + 4;
                new_PC           = PC + $signed({ {12{J_immed[20]}} , J_immed} << 1);
            end

            7'b1100011: //B-type
            begin
                case(funct3)
                    3'b000: branch_taken = REG_rs1_data == REG_rs2_data; //BEQ
                    3'b001: branch_taken = REG_rs1_data != REG_rs2_data;//BNE
                    3'b100: branch_taken = $signed(REG_rs1_data) < $signed(REG_rs2_data);//BLT
                    3'b101: branch_taken = $signed(REG_rs1_data) >= $signed(REG_rs2_data);//bge
                    3'b110: branch_taken = REG_rs1_data < REG_rs2_data;//bltu
                    3'b111: branch_taken = REG_rs1_data >= REG_rs2_data;//bgeu
                    default: invalid_instruction = 1;
                endcase

                if (branch_taken) new_PC = PC + $signed({{20{B_immed[12]}}, B_immed} << 1);
            end

            default: invalid_instruction = 1;
        endcase
        
        if (invalid_instruction || (!CPU_execute_enable) || terminate_interrupt)
        begin
            REG_write_enable    = 0;
            branch_taken        = 0;
            MEM_write_length    = 0;
            new_PC              = PC; //stuck here forever unitil we reset it.
        end
    end
endmodule