`default_nettype none

/*
*   Handles communication with working memory (SRAM).
*
*/
module sram_control 
    #(parameter N=8) (

    clk, 
    reset,
    start,
    write_op,
    read_data,
    write_data_in,
    mem_addr_in,

    finished,
    write_enable,         
    read_data_reg,
    write_data_out,    
    mem_addr_out      
    );


    input logic clk;
    input logic reset;
    input logic start;
    input logic write_op;
    input logic [N-1:0] read_data;          // From memory
    input logic [N-1:0] write_data_in;      // From controlling module
    input logic [N-1:0] mem_addr_in;        // From controlling module

    output logic finished;
    output logic write_enable;              // To memory
    output logic [N-1:0] read_data_reg;     // To controlling module
    output logic [N-1:0] write_data_out;    // To memory
    output logic [N-1:0] mem_addr_out;      // To memory


    logic read_reg_en;                      // Store value read from memory
    logic [5:0] state;

    // State encoding                     id_statebits 
    localparam [5:0] idle           = 6'b000_000;
    localparam [5:0] write_state    = 6'b001_010;
    localparam [5:0] read_state     = 6'b010_000;
    localparam [5:0] wait_read      = 6'b011_100;
    localparam [5:0] done           = 6'b100_001;
    
    // State machine outputs
    assign finished = state[0];
    assign write_enable = state[1];
    assign read_reg_en = state[2];

    // Pass data and address directly to memory module
    assign write_data_out = write_data_in;
    assign mem_addr_out = mem_addr_in;


    // Register memory output on wait_read state
    always_ff @(posedge clk or posedge reset) begin
        if (reset) read_data_reg <= 0;
        else if (read_reg_en)
            read_data_reg <= read_data;        
    end


    // State transition logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= idle;                       // Reset logic
        else begin
            case(state)     /* synthesis full_case */
                idle: begin 
                        if (start && write_op)
                            state <= write_state;       // Begin write operation
                        else if (start && !write_op)
                            state <= read_state;        // Begin read operation
                end
                    
                write_state: state <= done;
                read_state: state <= wait_read;         // Reading from RAM takes two cycles
                wait_read: state <= done;
                done: state <= idle;
                default: state <= idle;
            endcase    
        end
    end

endmodule

/*
* Author: Aloysio Campos & Rodrigo Barbosa  
* Handles writing of decrypted message to RAM.
* At every write operation determines if the data is valid (i.e. key is correct).
*/
module decrypted_ram_control 
    #(parameter N=8,                    // Data width
        parameter M=5,                  // Memory address width
        parameter CHAR_MAX=122,         // Maximum ASCII character value
        parameter CHAR_MIN=97,          // Minimum ASCII character value
        parameter CHAR_SPACE=32)        // Space character ASCII value (exception)
    (
    clk, 
    reset,
    start,
    write_data_in,
    mem_addr_in,

    finished,
    data_invalid,
    write_enable,
    write_data_out,    
    mem_addr_out      
    );

    input logic clk;
    input logic reset;
    input logic start;
    input logic [N-1:0] write_data_in;      // From controlling module
    input logic [M-1:0] mem_addr_in;        // From controlling module

    output logic finished;                  // To controlling module
    output logic data_invalid;              // Indicates if data is invalid. Stays high until reset
    output logic write_enable;              // To memory
    output logic [N-1:0] write_data_out;    // To memory
    output logic [M-1:0] mem_addr_out;      // To memory

    logic check_data;                       // Check if data is valid (reg enable)
    logic [3:0] state;

    // State encoding                    id_statebits 
    localparam [3:0] idle           = 4'b00_00;
    localparam [3:0] write_state    = 4'b01_00;
    localparam [3:0] check_write    = 4'b10_10;
    localparam [3:0] done           = 4'b11_01;
    
    // State machine outputs
    assign finished = state[0];
    assign check_data = state[1];

    // Pass data and address directly to memory module
    assign write_data_out = write_data_in;
    assign mem_addr_out = mem_addr_in;
    assign write_enable = 1'b1;             // Always writing to RAM


    // Logic to determine if output is valid ASCII character
    always_ff @(posedge clk or posedge reset) begin
        if (reset) data_invalid <= 0;
        else if (check_data) begin
            data_invalid <= (write_data_in > CHAR_MAX) ||       // Data above maximum allowed value
                            (write_data_in < CHAR_MIN) &&       // Data below minimum allowed value
                            (write_data_in != CHAR_SPACE);      // Data not a space character
        end   
    end


    // State transition logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= idle;   // Reset logic
        else begin
            case(state)     /* synthesis full_case */
                idle: begin 
                        if (start)
                            state <= write_state;       // Begin write operation
                end   

                write_state: state <= check_write;
                check_write: state <= done;             // Check if data is valid
                done: state <= idle;
                default: state <= idle;         
            endcase    
        end
    end

endmodule

/*
*
*/
module initialize_sram 
    #(parameter N = 8) (
    clk,
    reset,
    start,
    finished,
    sram_fsm_finished,
    sram_fsm_start,
    write_sram,
    sram_addr,
    sram_write_data
    );

    input logic clk;
    input logic reset;
    input logic start;
    output logic finished;

    // SRAM Control signals
    input logic sram_fsm_finished;
    output logic sram_fsm_start;
    output logic write_sram;
    output logic [N-1:0] sram_addr;
    output logic [N-1:0] sram_write_data;
    
    // Counter signals
    logic max_tick;                
    logic [N-1:0] addr_counter;
    logic counter_en;
    logic counter_reset;

    // Counter - Represents i value
    counter_to_max #(
        .MAX_COUNT(8'hFF), 
        .N(8)
        ) 
        i_counter (
            .clk(clk), 
            .reset(counter_reset),
            .en(counter_en),                    // Count up
            .max_tick(max_tick),                // Reached maximum value
            .out_count(addr_counter)
        );
    // Instantiation end

    logic [7:0] state;

    // State encoding                     id_statebits 
    localparam [7:0] idle           = 8'b000_00100;
    localparam [7:0] fill_sram      = 8'b001_11000;
    localparam [7:0] wait_fill      = 8'b011_01000;
    localparam [7:0] incr_counter   = 8'b010_00010;
    localparam [7:0] done           = 8'b100_00001;


    // State machine outputs
    assign finished = state[0];
    assign counter_en = state[1];
    assign counter_reset = state[2];           
    assign write_sram = state[3];
    assign sram_fsm_start = state[4];


    // Address register
    always_ff @(negedge clk or posedge reset) begin
        if (reset) sram_addr <= 0;
        else sram_addr <= addr_counter;   
    end


    // Write data register
    always_ff @(negedge clk or posedge reset) begin
        if (reset) sram_write_data <= 0;
        else sram_write_data <= addr_counter;         
    end



    // State transition logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= idle;   // Reset logic
        else begin
            case (state)     /* synthesis full_case */
                idle: begin 
                        if (start)
                            state <= fill_sram;
                end

                fill_sram: state <= wait_fill;

                wait_fill: begin
                    if (sram_fsm_finished && max_tick)          
                        state <= done;                          // Initialized all addresses
                    else if (sram_fsm_finished)
                        state <= incr_counter;                  // Go to next address
                end

                incr_counter: state <= fill_sram;               

                done: state <= idle;
                default: state <= idle;     
            endcase    
        end
    end

endmodule



module sram_swap_control
    #(parameter N = 8) (

    clk, 
    reset,
    start,
    finished,
    addr_select, 
    data_select,   
    sram_write,        
    sram_fsm_finished,
    read_data, 
    sram_fsm_start,
    write_data,
    si_reg,
    sj_reg
    );


    input logic clk; 
    input logic reset;
    input logic start;

    output logic finished;
    output logic addr_select;           // 0 = s, 1 = j
    output logic data_select;           // 0 = s, 1 = j. Data to be written. Ignored in read
    output logic sram_write;            // To memory_control. 0=R, 1=W
    
    // From/To memory_control fsm
    input logic sram_fsm_finished;
    input logic [N-1:0] read_data;      // Data from sram
    output logic sram_fsm_start;

    output logic [N-1:0] write_data;            // Data to be written to sram
    output logic [N-1:0] si_reg, sj_reg;       // Store s[i] and s[j]


    logic si_reg_en, sj_reg_en;         // Enable for s[i/j] registers

    logic [10:0] state;

    // State encoding
    localparam idle             = 11'b0000_00_00_00_0;
    localparam read_si          = 11'b0001_00_10_00_0;
    localparam wait_read_si     = 11'b0010_01_00_00_0;
    localparam read_sj          = 11'b0011_00_10_01_0;
    localparam wait_read_sj     = 11'b0100_10_00_01_0;
    localparam swap_1           = 11'b0101_00_11_01_0;         // Write s[i] in s[j]
    localparam wait_swap_1      = 11'b0110_00_01_01_0;
    localparam swap_2           = 11'b0111_00_11_10_0;         // Write s[j] in s[i]
    localparam wait_swap_2      = 11'b1000_00_01_10_0;
    localparam done             = 11'b1111_00_00_00_1;

    // State machine outputs
    assign finished = state[0];

    assign addr_select = state[1];
    assign data_select = state[2];

    assign sram_write = state[3];
    assign sram_fsm_start = state[4];

    assign si_reg_en = state[5];
    assign sj_reg_en = state[6];


    // Register to store s[i]
    always_ff @(posedge clk or posedge reset) begin
        if (reset) si_reg <= 0;
        else if (si_reg_en)
            si_reg <= read_data;  
    end

    // Register to store s[j]
    always_ff @(posedge clk or posedge reset) begin
        if (reset) sj_reg <= 0;
        else if (sj_reg_en)
            sj_reg <= read_data;
    end

    // Data to be written to memory (s[i] or s[j])
    always_comb begin
        case (data_select)
            0: write_data <= si_reg;
            1: write_data <= sj_reg;
        endcase     
    end


    
    // State transition logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= idle;   // Reset logic
        else begin
            case (state)     /* synthesis full_case */
                idle: begin 
                    if (start)
                        state <= read_si;
                end

                read_si: state <= wait_read_si;

                wait_read_si: begin
                    if (sram_fsm_finished)
                        state <= read_sj;
                end

                read_sj: state <= wait_read_sj;

                wait_read_sj: begin
                    if (sram_fsm_finished)
                        state <= swap_1;
                end

                swap_1: state <= wait_swap_1;

                wait_swap_1: begin
                    if (sram_fsm_finished)
                        state <= swap_2;
                end

                swap_2: state <= wait_swap_2;

                wait_swap_2: begin
                    if (sram_fsm_finished)
                        state <= done;
                end

                done: state <= idle;            
                default: state <= idle;
                    
            endcase    
        end
    end

endmodule



module control_swap (
    clk,
    reset,
    start_task2,
    secret_key,
    done,
    memory_finish,
    memory_data,      
    sram_control_start,           
    sram_write_op,   
    address,
    sram_write_data,     
    swap_done,
    addr_select,
    swap_start_mem,             
    swap_sram_write,        
    swap_write_data,
    start_swap
    );

    input logic clk;
    input logic reset;
    input logic start_task2;
    input logic [23:0] secret_key;
    output logic done;

    // sram_control Signals
    input logic memory_finish;
    input logic [7:0] memory_data;              // Data read from SRAM
    output logic sram_control_start;
    output logic sram_write_op;   
    output logic [7:0] address;
    output logic [7:0] sram_write_data;         // Passes swap data to sram controller

    // sram_swap_control Signals
    input logic swap_done;
    input logic addr_select;
    input logic swap_start_mem;             // From swap to start sram_control
    input logic swap_sram_write;            // write_op
    input logic [7:0] swap_write_data;
    output logic start_swap;


    // Signals from fsm to sram_control
    logic start_mem;
    logic swap_control;
    logic write_op;

    logic [7:0] which_key_byte;                    

    // Create counter variable
    logic [7:0] counter = 8'b0; // i
    logic [7:0] j = 8'b0;

    // Select which address to output to memory
    assign address = addr_select ? j : counter;

    // Mux to control SRAM
    always_comb begin
        case(swap_control)
            0: {sram_control_start, sram_write_op} = {start_mem, write_op};
            1: {sram_control_start, sram_write_op} = {swap_start_mem, swap_sram_write};
        endcase 
    end

    // Passes swap data to sram_control
    assign sram_write_data = swap_write_data;

    //create state variable
    logic [11:0] state;

    // Encode states with outputs to prevent glitches
    // Outputs using state bits: swap_control, write_op, start_mem, start_swap, done
    //                name = 12'b OUT_ONEHOT
    localparam [11:0] idle              = 12'b00000_0000001;
    localparam [11:0] read_ram          = 12'b00100_0000010;
    localparam [11:0] wait_read         = 12'b00000_0000100;
    localparam [11:0] add_all           = 12'b10010_0001000;
    localparam [11:0] wait_done         = 12'b10000_0010000;
    localparam [11:0] done_encoding     = 12'b00001_0100000;
    localparam [11:0] add_i             = 12'b00000_1000000;

    assign swap_control = state[11];
    assign write_op = state[10];
    assign start_mem = state[9];
    assign start_swap = state[8];
    assign done = state[7];

    // Determines which byte of secret_key to use in computation
    always_comb begin
     case(counter%3)
        0: which_key_byte = secret_key[23:16];
        1: which_key_byte = secret_key[15:8];
        2: which_key_byte = secret_key[7:0];
        default: which_key_byte = 8'hFF;        // Debug value
     endcase
    end

    //state logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
        state <= idle;
        counter <= 8'b0;
        j <= 8'b0;
        end

        else begin
            case(state) /* synthesis full_case */
                    idle: begin 
                        if (start_task2)
                            state <= read_ram;
                        counter <= counter;
                        j <= j;
                    end
                    read_ram: begin 
                        state <= wait_read;
                        counter <= counter;
                        j <= j;
                    end
                    wait_read: begin 
                        if (memory_finish)
                            state <= add_all;
                        counter <= counter;
                        j <= j;
                    end
                    add_all: begin 
                        state <= wait_done;
                        counter <= counter;
                        j <= j + memory_data + which_key_byte;
                    end
                    wait_done: begin 
                        j <= j;
                        if(!swap_done)
                            state <= wait_done;
                        else if (swap_done &&(counter !== 255))
                            state <= add_i;
                        else 
                            state <= done_encoding;
                        counter <= counter;
                    end
                    done_encoding: begin 
                        j <= j;
                        state <= idle;      // was done_encoding
                        counter <= counter;
                    end
                    add_i: begin
                        j <= j;
                        state <= read_ram;
                        counter <= counter + 1'b1;
                    end

                    default: begin state <= idle; j <= 0; counter <= 0; end
            endcase
        end
    end

endmodule

module decrypt_message (
    reset,
    clk,
    start,
    memory_done,
    swap_done,
    ROM_done,
    RAM_done,
    MEM_read,
    encrypted_input_ROM,
    swap_start_mem,             
    swap_sram_write,            
    Si,
    Sj,
    swap_write_data,
    swap_select_address,
    start_ROM,
    start_RAM,
    start_swap,
    sram_control_start,
    write_op,
    addr_MEM,
    addr_RAM,
    addr_ROM,
    done,
    decrypted_output_to_RAM,
    sram_write_data
    );

    input logic reset;
    input logic clk;
    input logic start;
    //dones from other FSMs
    input logic memory_done;
    input logic swap_done;
    input logic ROM_done;
    input logic RAM_done;
    //memory reads
    input logic [7:0] MEM_read;
    input logic [7:0] encrypted_input_ROM;
    //data from swap
    input logic swap_start_mem;             // From swap to start sram_control
    input logic swap_sram_write;            // write_op
    input logic [7:0] Si;
    input logic [7:0] Sj;
    input logic [7:0] swap_write_data;
    //selecting memory address output
    input logic swap_select_address;

    output logic start_ROM;
    output logic start_RAM;
    output logic start_swap;
    output logic sram_control_start;
    output logic write_op;
    output logic [7:0] addr_MEM;
    output logic [4:0] addr_RAM;
    output logic [4:0] addr_ROM;
    output logic done;
    output logic [7:0] decrypted_output_to_RAM;

    output logic [7:0] sram_write_data;

    logic mux_select_address;
    logic swap_control;                     // Gives control of sram to swap
    logic start_MEM;                        // Local sram control
    
    //                 
    logic [20:0]state ;
    logic [7:0] added_value ;
    logic [7:0] i;
    logic [7:0] j;
    logic [4:0] k;


                        //19'b ONEHOT_startMEM_startRAM_startROM_startSwap_muxSeladdr
    localparam [20:0] idle          = 21'b000000_0000_0001_0000000;
    localparam [20:0] addi          = 21'b000000_0000_0010_0000000;
    localparam [20:0] readSi        = 21'b000000_0000_0100_0010000;
    localparam [20:0] wait_MEM_1    = 21'b000000_0000_1000_0000000;
    localparam [20:0] addj          = 21'b000000_0001_0000_0100010;
    localparam [20:0] wait_swap     = 21'b000000_0010_0000_0100000;
    localparam [20:0] readSiSj      = 21'b000000_0100_0000_0010001;
    localparam [20:0] wait_MEM_2    = 21'b000000_1000_0000_0000001;
    localparam [20:0] read_ROM      = 21'b000001_0000_0000_0000100;
    localparam [20:0] wait_ROM      = 21'b000010_0000_0000_0000000;
    localparam [20:0] write_RAM     = 21'b000100_0000_0000_0001000;
    localparam [20:0] wait_RAM      = 21'b001000_0000_0000_0000000;
    localparam [20:0] add_k         = 21'b010000_0000_0000_0000000;
    localparam [20:0] DONE          = 21'b100000_0000_0000_1000000;
    //14 states

    assign mux_select_address = state[0];
    assign start_swap = state [1];
    assign start_ROM = state[2];
    assign start_RAM = state[3];
    assign start_MEM = state[4];
    assign swap_control = state[5];
    assign done = state[6];

    assign write_op = swap_sram_write;  // To sram - was 0
    assign addr_RAM = k;
    assign addr_ROM = k;



    // Mux determines address to pass to sram_control
    always_comb begin
        if(mux_select_address)
            addr_MEM = (Si+Sj);
        else if (swap_select_address)
            addr_MEM = j;   //------------------------------------------------------DEFAULT I OR J WHEN SWAP_SEL = 0/1?
        else
            addr_MEM = i;
    end
    //assign addr_MEM = mux_select_address? (Si + Sj) : (swap_select_address ? i : j);

        // Mux to control SRAM
    always_comb begin
        case(swap_control)
            0: sram_control_start = start_MEM;          // local controls
            1: sram_control_start = swap_start_mem;     // swap controls
        endcase 
    end

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
        state <= idle; k <= 5'b0 ; i <= 8'b0; j <= 8'b0; decrypted_output_to_RAM <= 8'b0;end
        else
        case(state)  /* synthesis full_case */
                idle : begin 
                    if(start)
                        state <= addi;
                end
                addi  : begin 
                    state <= readSi;
                    i <= i+1;
                end
                readSi : begin 
                    state <= wait_MEM_1;
                end 
                wait_MEM_1 : begin 
                    if(memory_done)
                        state <= addj;
                end 
                addj : begin 
                    state <= wait_swap;
                    j <= j + MEM_read;
                end 
                wait_swap : begin 
                    if(swap_done)
                        state <= readSiSj;
                end 
                readSiSj : begin
                    state <= wait_MEM_2;
                end 
                wait_MEM_2 : begin 
                    if(memory_done)
                        state <= read_ROM;
                end
                read_ROM : begin 
                    state <= wait_ROM;
                end
                wait_ROM : begin 
                    decrypted_output_to_RAM <= encrypted_input_ROM ^ MEM_read;
                    if(ROM_done)
                        state <= write_RAM;
                end
                write_RAM : begin 
                    state <= wait_RAM;
                end 
                wait_RAM : begin 
                    if(RAM_done)
                        state <= add_k;
                end 
                add_k : begin 
                    if(k !== 31) begin    
                        k <= k + 1;
                        state <= addi;
                    end
                    else
                        state <= DONE;
                end 
                DONE : begin 
                    state <= idle;
                end 
            default: begin  state <= idle; k <= 5'b0 ; i <= 8'b0; j <= 8'b0; decrypted_output_to_RAM <= 8'b0; end
        endcase
    end

    // Pass along swap data to write to sram
    assign sram_write_data = swap_write_data;
 

endmodule


/*
* NEW DESCRIPTION!
* Author: Rodrigo Barbosa
* Takes in a 32 bit word and outputs one byte at a time
* Source: modified Mod-m counter - CHU 4.11 pg 65
*/
module counter_to_max 
    #( parameter N = 8, 
        parameter MAX_COUNT = 8'hFF,    // Maximum value
        parameter MIN_COUNT = 8'h00)    // Start Value
        
    (
    clk, reset,
    en,

    max_tick,
    out_count
    );
        
    input logic clk, reset;
    input logic en;
    
    output logic max_tick;
    output logic [N-1:0] out_count;

    // signal declaration
    logic [N-1:0] count_next;

    // register
    always_ff @(posedge clk, posedge reset) begin
        if (reset) out_count <= MIN_COUNT;
        else if (en) out_count <= count_next;        
    end

    // next state logic
    assign count_next = (out_count==(MAX_COUNT)) ? MIN_COUNT : (out_count+1);

    assign max_tick = (out_count==(MAX_COUNT)) ? 1'b1 : 1'b0;       // limit reached

endmodule
