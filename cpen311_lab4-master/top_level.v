`default_nettype none

module top_level(
    clk,
    reset,
    start,

    sram_read_data,
    sram_write_enable,
    sram_write_data,
    sram_addr,
    		
	ram_addr,			
	ram_write_data,		
	ram_write_enable,	
	ram_read_data,	

	rom_addr,			
	rom_read_data,

    key_not_found,
    key_found,

    //Signals to HEX 
    secret_key_0,
    secret_key_1,
    secret_key_2,
    secret_key_3,
    secret_key_4,
    secret_key_5
    	
	);
	
	input logic clk;
	input logic reset;
	input logic start;


	// Signals from/to sram
	input logic [7:0] sram_read_data;
	output logic sram_write_enable;     
	output logic [7:0] sram_write_data;
	output logic [7:0] sram_addr;  

    // Signals from/to decrypted_RAM
    output logic [4:0] ram_addr;			
	output logic [7:0] ram_write_data;		
	output logic ram_write_enable;	
	input logic [7:0] ram_read_data;

    // Signals from/to encrypted_ROM
    output logic [4:0] rom_addr;			
    input logic [7:0] rom_read_data;

	//Signals to LEDs
    output logic key_not_found;
    output logic key_found;

    //Signals to HEX 
    output logic [3:0] secret_key_0;
    output logic [3:0] secret_key_1;
    output logic [3:0] secret_key_2;
    output logic [3:0] secret_key_3;
    output logic [3:0] secret_key_4;
    output logic [3:0] secret_key_5;


    /*
    * GENERAL SYNTAX FOR ALGORITHM STAGES. Will be going into control MUX
    * logic STAGENAME_SIGNAL; Eg:
    * logic initialize_start;             
    * logic initialize_reset;
    * logic initialize_finished;
    */

    // Initialize SRAM FSM Signals
    logic initialize_start;             
    logic initialize_reset;
    logic initialize_finished;
    logic initialize_sram_control_start;
    logic initialize_write_sram;
    logic [7:0] initialize_sram_addr;
    logic [7:0] initialize_sram_write_data;

    // Shuffle SRAM FSM Signals
    logic shuffle_start;             
    logic shuffle_reset;
    logic shuffle_finished;
    logic shuffle_sram_control_start;       // To sram
    logic shuffle_write_sram;               // To sram
    logic shuffle_start_swap;               // To swap
    logic [7:0] shuffle_sram_addr;          // To sram
    logic [7:0] shuffle_sram_write_data;    // To sram

    // Compute message FSM Signals
    logic compute_start;             
    logic compute_reset;
    logic compute_finished;
    logic compute_sram_control_start;       // To sram
    logic compute_write_sram;               // To sram
    logic compute_start_swap;               // To swap
    logic [7:0] compute_sram_addr;          // To sram
    logic [7:0] compute_sram_write_data;    // To sram
    

    // Control MUX signals
    logic [1:0] control_select;

    // sram_control Signals
	logic sram_control_reset;
	logic sram_control_start;         
	logic sram_write_op;              
	logic [7:0] sram_write_data_in;      
	logic [7:0] sram_addr_in;        

	logic sram_finished;         
	logic [7:0] sram_read_data_reg;         // To controlling module

    // rom_control Signals
    logic encrypted_rom_control_start;
    logic encrypted_rom_control_reset;
    logic rom_finished;                     
    logic [4:0] rom_addr_in;
    logic [7:0] rom_read_data_reg;

    // ram_control Signals
    logic decrypted_ram_control_start;
    logic decrypted_ram_control_reset;
    logic ram_finished;
    logic ram_data_invalid;    
    logic [4:0] ram_addr_in;
    logic [7:0] ram_write_data_in;


    // SRAM Swap Control Signals
    logic swap_reset;
    logic swap_start;
    logic swap_finished;
    logic swap_addr_select;                     // 0 = s, 1 = j
    logic swap_data_select;                     // 0 = s, 1 = j. Data to be written. Ignored in read
    logic swap_sram_write;                      // To memory_control. 0=R, 1=W
    logic swap_sram_fsm_start;                  // starts sram_control fsm
    logic [7:0] swap_write_data;                // Data to be written to sram
    logic [7:0] swap_si_reg, swap_sj_reg;       // Store s[i] and s[j]

    // Key Counter Signals
    logic reset_key;
    logic en_next_key;
    logic max_key;
    logic [24:0] secret_key; 

    // HEX Signals
    assign secret_key_0 = secret_key[3:0];
    assign secret_key_1 = secret_key[7:4];
    assign secret_key_2 = secret_key[11:8];
    assign secret_key_3 = secret_key[15:12];
    assign secret_key_4 = secret_key[19:16];
    assign secret_key_5 = secret_key[23:20];


    // Algorithm Controlling FSM
    master_fsm master_fsm0 (
        .clk(clk),
        .reset(reset),
        .start(start),
        .finished(key_found),

        // Initialize SRAM FSM Signals
        .initialize_finished(initialize_finished),
        .initialize_start(initialize_start),             
        .initialize_reset(initialize_reset),
    
        // Shuffle SRAM FSM Signals
        .shuffle_finished(shuffle_finished),
        .shuffle_start(shuffle_start),             
        .shuffle_reset(shuffle_reset),

        // Compute message FSM  Signals
        .compute_finished(compute_finished),
        .compute_start(compute_start),
        .compute_reset(compute_reset),
        .data_invalid(ram_data_invalid),
        
        // Memory interfaces Reset Signals
        .swap_reset(swap_reset),
        .sram_reset(sram_control_reset),
        .decr_ram_reset(decrypted_ram_control_reset),
	    .encr_rom_reset(encrypted_rom_control_reset),
        
        // Counter Signals
        .max_key(max_key),
	    .en_next_key(en_next_key),
	    .reset_key(reset_key),
	    .key_not_found(key_not_found),

        // Control MUX Signals
        .control_select(control_select)
    );


    // Initialize SRAM - Part 1 of algorithm
    initialize_sram #(
        .N(8) 
        )
        initialize_stage (
            .clk(clk),
            .reset(initialize_reset),
            .start(initialize_start),
            .finished(initialize_finished),
            .sram_fsm_finished(sram_finished),
            .sram_fsm_start(initialize_sram_control_start),
            .write_sram(initialize_write_sram),
            .sram_addr(initialize_sram_addr),
            .sram_write_data(initialize_sram_write_data)
        );
    // Instantiation end


	// Shuffle SRAM - Part 2 of algorithm
    control_swap shuffle_stage (           
        .clk(clk),
        .reset(shuffle_reset),
        .start_task2(shuffle_start),
        .secret_key(secret_key[23:0]),                      // DEBUGGGGGGGGGG!!!!!!!!!!! 24'h000249 secret_key[23:0]
        .done(shuffle_finished),
        .memory_finish(sram_finished),
        .memory_data(sram_read_data_reg),      
        .sram_control_start(shuffle_sram_control_start),           
        .sram_write_op(shuffle_write_sram),   
        .address(shuffle_sram_addr),
        .sram_write_data(shuffle_sram_write_data),     
        .swap_done(swap_finished),
        .addr_select(swap_addr_select),
        .swap_start_mem(swap_sram_fsm_start),             
        .swap_sram_write(swap_sram_write),        
        .swap_write_data(swap_write_data),
        .start_swap(shuffle_start_swap)  
    );


    // Decrypt message - Part 3 of algorithm
    decrypt_message compute_stage (
        .clk(clk),
        .reset(compute_reset),
        .start(compute_start),
        .done(compute_finished),   

        .memory_done(sram_finished),                        // From sram_control
        .MEM_read(sram_read_data_reg),                      // From sram_control
        .sram_control_start(compute_sram_control_start),    // To sram_control - MUX!!!!!!!!
        .write_op(compute_write_sram),                      // To sram_control - MUX!!!!!!!!  
        .addr_MEM(compute_sram_addr),                       // To sram_control - MUX!!!!!!!!
        .sram_write_data(compute_sram_write_data),

        .swap_done(swap_finished),                  // From swap_control
        .swap_start_mem(swap_sram_fsm_start),       // From swap_control
        .swap_sram_write(swap_sram_write),          // From swap_control
        .Si(swap_si_reg),                           // From swap_control
        .Sj(swap_sj_reg),                           // From swap_control
        .swap_select_address(swap_addr_select),     // From swap_control
        .swap_write_data(swap_write_data),           // From swap_control
        .start_swap(compute_start_swap),            // To swap_control - MUX!!!!!!!!

        .ROM_done(rom_finished),                    // From ROM_read
        .encrypted_input_ROM(rom_read_data_reg),    // From ROM_read
        .start_ROM(encrypted_rom_control_start),    // To ROM_read
        .addr_ROM(rom_addr_in),                     // To ROM_read 

        .RAM_done(ram_finished),                    // From RAM_write
        .start_RAM(decrypted_ram_control_start),    // To RAM_write
        .addr_RAM(ram_addr_in),                     // To RAM_write
        .decrypted_output_to_RAM(ram_write_data_in) // To RAM_write
    );



    
	sram_control sram_control0 (
		.clk(clk),
		.reset(sram_control_reset),
		.start(sram_control_start),               // From controlling module
		.write_op(sram_write_op),                 // From controlling module
		.read_data(sram_read_data),               // From memory
		.write_data_in(sram_write_data_in),       // From controlling module
		.mem_addr_in(sram_addr_in),               // From controlling module
		
		.finished(sram_finished),                 // To controlling module
		.write_enable(sram_write_enable),         // To memory      
		.read_data_reg(sram_read_data_reg),       // To controlling module
		.write_data_out(sram_write_data),         // To memory
		.mem_addr_out(sram_addr)                  // To memory
	);
    


    // Control mux. Determines which fsm is interfacing with sram_control at a given time
    always_comb begin
        case(control_select)
            2'b00: {sram_control_start, sram_write_op, sram_write_data_in, sram_addr_in} = {1'b0,1'b0,8'hAA,8'hBB};
            2'b01: {sram_control_start, sram_write_op, sram_write_data_in, sram_addr_in} = {initialize_sram_control_start, initialize_write_sram, initialize_sram_write_data, initialize_sram_addr};
            2'b10: {sram_control_start, sram_write_op, sram_write_data_in, sram_addr_in} = {shuffle_sram_control_start, shuffle_write_sram, shuffle_sram_write_data, shuffle_sram_addr};
            2'b11: {sram_control_start, sram_write_op, sram_write_data_in, sram_addr_in} = {compute_sram_control_start, compute_write_sram, compute_sram_write_data, compute_sram_addr};
        endcase  
    end

   
    
    decrypted_ram_control #(
        .N(8),      // Data width
        .M(5),      // Memory address width (32 word)
        .CHAR_MAX(122),     // Maximum ASCII character value
        .CHAR_MIN(97),      // Minimum ASCII character value
        .CHAR_SPACE(32)     // Space character ASCII value (exception)
        )
        decrypted_ram_control_instance (
            .clk(clk), 
            .reset(decrypted_ram_control_reset),
            .start(decrypted_ram_control_start),    // From controlling module
            .write_data_in(ram_write_data_in),      // From controlling module
            .mem_addr_in(ram_addr_in),              // From controlling module

            .finished(ram_finished),                // To controlling module
            .data_invalid(ram_data_invalid),        // To controlling module
            .write_enable(ram_write_enable),        // To memory          
            .write_data_out(ram_write_data),        // To memory
            .mem_addr_out (ram_addr)                // To memory
        );
    // Instantiation end
    
    

    // Reused sram_control module
    sram_control encrypted_rom_control (
		.clk(clk),
		.reset(encrypted_rom_control_reset),
		.start(encrypted_rom_control_start),        // From controlling module
		.write_op(1'b0),                            // Always reading
		.read_data(rom_read_data),                  // From memory
		//.write_data_in(NOT USED),       
		.mem_addr_in(rom_addr_in),                  // From controlling module
		
		.finished(rom_finished),                    // To controlling module
		//.write_enable(NOT USED),                            
		.read_data_reg(rom_read_data_reg),          // To controlling module
		//.write_data_out(NOT USED),                
		.mem_addr_out(rom_addr)                     // To memory
	);


    /*
    encrypted_rom_control #(
        .N(8)
        ) 
        encrypted_rom_control_instance (
            .clk(clk), 
            .reset(encrypted_rom_control_reset),
            .start(encrypted_rom_control_start),// From controlling module
            .read_data(rom_read_data),          // From memory
            .mem_addr_in(rom_addr_in),           // From controlling module

            .finished(rom_finished),            // To controlling module                  
            .read_data_reg(rom_read_data_reg),  // To controlling module 
            .mem_addr_out(rom_addr)                      // To memory
        );
    // Instantiation end
    */
    




	// Swap_fsm - contains mux
    sram_swap_control #(
        .N(8)
        )
        sram_swap_control0 (
            .clk(clk),                              // in
            .reset(swap_reset),                     // in
            .start(swap_start),                     // in - mux
            .finished(swap_finished),               // out
            .addr_select(swap_addr_select),         // out
            .data_select(swap_data_select),         // out
            .sram_write(swap_sram_write),           // out
            .sram_fsm_finished(sram_finished),      // in
            .read_data(sram_read_data_reg),         // in - Data from sram
            .sram_fsm_start(swap_sram_fsm_start),   // out
            .write_data(swap_write_data),           // out
            .si_reg(swap_si_reg),                   // out
            .sj_reg(swap_sj_reg)                    // out
        );
    // Instantiation end

    // Control mux. Determines which fsm is interfacing with other modules at a given time
    always_comb begin
        case(control_select[0])     // Only odd bit necessary
            0: swap_start = shuffle_start_swap;     // STAGE 2
            1: swap_start = compute_start_swap;     // STAGE 3
        endcase  
    end



    
    // Key Counter
    counter_to_max #(
        .N(25),
        .MAX_COUNT(25'b0_01000000_00000000_00000000),       // For all possible 24 bit keys set to 25'b1_00000000_00000000_00000000
        .MIN_COUNT(0)
        ) 

        key_counter (
            .clk(clk), 
            .reset(reset_key),
            .en(en_next_key),
            .max_tick(max_key),
            .out_count(secret_key)
        );
    // Instantiation end

    // NOTE: REARRANGE TO BETTER ORGANIZE MODULES AND SIGNALS

    /*
        For bonus part:
            Implement MIN_VAL in counter to reset to a known value other than 0. Set keyspace
            Use switches to determine which running counter to display
                i.e.    SW[1:0] = 0 - Display core 0 key
                        SW[1:0] = 1 - Display core 1 key...

    */



endmodule