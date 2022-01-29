`default_nettype none
/*
* Controls the algorithm and data flow
*/
module master_fsm (
    clk,
	reset,
	start,
    finished,

    initialize_finished,
    initialize_start,             
    initialize_reset,
    
    shuffle_finished,
    shuffle_start,             
    shuffle_reset,

    compute_finished,
	data_invalid,
    compute_start,
    compute_reset,

    swap_reset,
    sram_reset,
	decr_ram_reset,
	encr_rom_reset,

    control_select,

	max_key,
	en_next_key,
	reset_key,
	key_not_found
	);

    input logic clk;
	input logic reset;
	input logic start;
    output logic finished;

    // Initialize SRAM FSM Signals
    input logic initialize_finished;
    output logic initialize_start;             
    output logic initialize_reset;
    
    // Shuffle SRAM FSM Signals
    input logic shuffle_finished;
    output logic shuffle_start;             
    output logic shuffle_reset;

    // Compute message FSM  Signals
    input logic compute_finished;
	input logic data_invalid;
    output logic compute_start;
    output logic compute_reset;

    // swap_control and sram_control Reset Signals
    output logic swap_reset;
    output logic sram_reset;
	output logic decr_ram_reset;
	output logic encr_rom_reset;

    // Control mux signals
    output logic [1:0] control_select;

	// Key counter
	input logic max_key;
	output logic en_next_key;
	output logic reset_key;
	output logic key_not_found;
	
    logic [19:0] state;

	// State encoding    				id_counter_start_ctrl_rst_finished
	localparam [19:0] idle                  = 20'b0000_100_000_00_1111111_0;
	localparam [19:0] begin_initialize      = 20'b0001_000_001_01_0000000_0;
	localparam [19:0] wait_initialize       = 20'b0010_000_000_01_0000000_0;
	localparam [19:0] begin_shuffle         = 20'b0011_000_010_10_0000000_0;    
	localparam [19:0] wait_shuffle          = 20'b0100_000_000_10_0000000_0;    
	localparam [19:0] begin_compute         = 20'b0101_000_100_11_0000000_0;    
	localparam [19:0] wait_compute          = 20'b0110_000_000_11_0000000_0;    
	localparam [19:0] done_succ             = 20'b0111_000_000_00_0000000_1;
	localparam [19:0] change_key			= 20'b1000_010_000_00_1111111_0;
	localparam [19:0] done_fail				= 20'b1001_001_000_00_0000000_0;
	

	// State machine outputs
	assign finished = state[0];

	assign initialize_reset = state[1];
	assign shuffle_reset = state[2];
	assign compute_reset = state[3];
	assign swap_reset = state[4];
    assign sram_reset = state[5];
	assign decr_ram_reset = state[6];
	assign encr_rom_reset = state[7];

	assign control_select = state[9:8];

	assign initialize_start = state[10];
	assign shuffle_start = state[11];
	assign compute_start = state[12];

	assign key_not_found = state[13];
	assign en_next_key = state[14];
	assign reset_key = state[15];


	always_ff @(posedge clk or posedge reset) begin
		if (reset) state <= idle;   // Reset logic
		else begin
			case (state)     /* synthesis full_case */
				idle: begin 
				    if (start)
						state <= begin_initialize;
				end

				begin_initialize: state <= wait_initialize;
                    
                wait_initialize: begin					// Wait until first loop is finished
                    if (initialize_finished)
                        state <= begin_shuffle;
                end
                
                begin_shuffle: state <= wait_shuffle;
                    
                wait_shuffle: begin						// Wait until second loop is finished
                    if (shuffle_finished)
                        state <= begin_compute;   
                end

				begin_compute: state <= wait_compute;
                    
                wait_compute: begin						// Wait until third loop is finished
					if (data_invalid)					// Abort computation if data is invalid (wrong key)
						state <= change_key;
                    else if (compute_finished)
                        state <= done_succ;				// Successful if all data is valid
                end


				change_key: begin
					if (max_key)
						state <= done_fail;				// Failed if no key was found within keyspace
					else 
						state <= begin_initialize;		// Restart algorithm with different key
					
				end

				done_fail: state <= done_fail;
				done_succ: state <= done_succ;   
				default: state <= idle;
						  
			endcase    
		end
	end

endmodule