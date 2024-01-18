module TOP
(
    input SYS_clk,
    input SYS_reset,
    input SYS_start_button,
    input terminate_interrupt_button,

    input rx,

    input INS_DATA_sw,

    output INS_DATA_sel,
    
    // tx interface
    output tx,
    output clk_locked,
    output CPU_execute_enable,
    output CPU_finish_execution
);
    wire clk_5;

    // wire       receive_buffer_full, receive_buffer_empty;
    wire       rxDone; 
    wire       txDone;
    
    wire [7:0] data_from_rx;   // from rx
    wire [7:0] data_fromMem;   // to tx
    wire       inst_to_CPU_valid;
    wire [7:0] inst_to_CPU;  
    wire       data_to_CPU_valid;
    wire [7:0] data_to_CPU;   

    wire       CPU_read_request = ~CPU_execute_enable;
    wire       data_fromMem_valid;
    wire       transmitter_request;
    wire       transmitter_buffer_full, transmitter_buffer_empty;
    wire       DMEM_transmit_request;
    wire [7:0] DMEM_data_transmit;
    
    wire       write_instruction_request = rxDone & (~INS_DATA_sw);
    wire       write_data_request        = rxDone &   INS_DATA_sw;

    assign INS_DATA_sel = INS_DATA_sw;
    clock_wizard_wrapper clock_generator
    (   
        //INPUT
        .sys_clock  (SYS_clk),

        //OUTPUT
        .clk_5mhz   (clk_5),
        .clk_locked (clk_locked)
    );


    Receiver Rx 
    (   
        //INPUT
        .clk        (clk_5), 
        .rx         (rx), 
        .SYS_reset  (SYS_reset), 

        //OUTPUT
        .data_out   (data_from_rx), 
        .rxDone     (rxDone)
    );

    fifo_buffer receive_data_buffer
    (
        //INPUT
        .clk            (clk_5),
        .SYS_reset      (SYS_reset), 
        .write_request  (write_data_request), 
        .data_in        (data_from_rx), 
        .read_request   (CPU_read_request),

        //OUTPUT
        .data_valid     (data_to_CPU_valid),
        .data_out       (data_to_CPU)
    );;

    fifo_buffer receive_instruction_buffer 
    (
        //INPUT
        .clk            (clk_5),
        .SYS_reset      (SYS_reset), 
        .write_request  (write_instruction_request), 
        .data_in        (data_from_rx), 
        .read_request   (CPU_read_request),

        //OUTPUT
        // .full           (receive_buffer_full), 
        // .empty          (receive_buffer_empty),
        .data_valid     (inst_to_CPU_valid),
        .data_out       (inst_to_CPU)
    );

    
    RISCV_CPU RISCV_CPU
    (
        //INPUT
        .clk                    (clk_5),
        .SYS_reset              (SYS_reset),
        .SYS_start_button       (SYS_start_button),
        .terminate_interrupt_button(terminate_interrupt_button),
        
        .inst_to_CPU_valid      (inst_to_CPU_valid),
        .inst_to_CPU            (inst_to_CPU),
        .data_to_CPU_valid      (data_to_CPU_valid),
        .data_to_CPU            (data_to_CPU),
        .transmitter_buffer_full(transmitter_buffer_full),

        //OUTPUT
        .DMEM_transmit_request  (DMEM_transmit_request),
        .DMEM_data_transmit     (DMEM_data_transmit),
        .CPU_finish_execution   (CPU_finish_execution),
        .CPU_execute_enable     (CPU_execute_enable)
    );

    fifo_buffer transmit_data_buffer
    (
        //INPUT
        .clk            (clk_5),
        .SYS_reset      (SYS_reset), 
        .write_request  (DMEM_transmit_request), 
        .data_in        (DMEM_data_transmit), 
        .read_request   (transmitter_request),

        //OUTPUT
        .full           (transmitter_buffer_full), 
        .empty          (transmitter_buffer_empty),
        .data_valid     (data_fromMem_valid),
        .data_out       (data_fromMem)
    );

    Transmitter Tx 
    (
        //INPUT
        .clk            (clk_5), 
        .SYS_reset      (SYS_reset), 
        .buffer_empty   (transmitter_buffer_empty),
        .data_in        (data_fromMem), 
        .data_valid     (data_fromMem_valid),

        //OUTPUT
        .data_requesting(transmitter_request),
        .tx             (tx), 
        .txDone         (txDone)
    );
endmodule