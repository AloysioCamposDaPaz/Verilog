`default_nettype none

/*
 * Handles the modulation of a carrier sine wave
 */
module modulate_carrier
    #( parameter DEFAULT_DDS_INCR = 32'd258)        // Default to 3Hz
    (       
    clk,
    modulating_bits,
    modulation_selector,
    carrier_sin_wave,
    carrier_cos_wave,
    fsk_dds_increment,    

    modulated_wave_reg,
    dds_increment
    );

    input logic clk;
    input logic [1:0] modulating_bits;
    input logic [2:0] modulation_selector;
    input logic signed [11:0] carrier_sin_wave;
    input logic signed [11:0] carrier_cos_wave;
    input logic [31:0] fsk_dds_increment;    

    output logic signed [11:0] modulated_wave_reg;
    output logic [31:0] dds_increment;


    logic signed [11:0] modulated_wave;
    logic signed [11:0] ask_modulation;
    logic signed [11:0] bpsk_sin_modulation;
    logic signed [11:0] lfsr_modulation;
    logic signed [11:0] qpsk_modulation;

    // QPSK signals
    logic signed [11:0] bpsk_cos_modulation;
    logic signed [23:0] qpsk_intermediate_val;      // Holds result of the multiplication. Large enough to never overflow

    // Select which modulation to output
    always_comb begin
        case (modulation_selector)
            3'b000: {modulated_wave, dds_increment} = {ask_modulation, DEFAULT_DDS_INCR};           // ASK
            3'b001: {modulated_wave, dds_increment} = {carrier_sin_wave, fsk_dds_increment};        // FSK
            3'b010: {modulated_wave, dds_increment} = {bpsk_sin_modulation, DEFAULT_DDS_INCR};      // BPSK
            3'b011: {modulated_wave, dds_increment} = {lfsr_modulation, DEFAULT_DDS_INCR};          // LFSR
            3'b100: {modulated_wave, dds_increment} = {qpsk_modulation, DEFAULT_DDS_INCR};          // ASK
            default: {modulated_wave, dds_increment} = {ask_modulation, DEFAULT_DDS_INCR};          // Default to ASK
        endcase
        
    end

    // ASK modulation
    always_comb begin
        if (modulating_bits[0])
            ask_modulation = carrier_sin_wave;
        else 
            ask_modulation = 12'b0000_0000_0000;
    end

    // BPSK modulation on sine wave
    always_comb begin
        if (modulating_bits[0])
            bpsk_sin_modulation = (carrier_sin_wave^12'b1111_1111_1111) + 1'b1;
        else 
            bpsk_sin_modulation = carrier_sin_wave;
    end

    // BPSK modulation on cosine wave
    always_comb begin
        if (modulating_bits[1])
            bpsk_cos_modulation = (carrier_cos_wave^12'b1111_1111_1111) + 1'b1;
        else 
            bpsk_cos_modulation = carrier_cos_wave;
    end

    // LFSR 
    always_comb begin
        if (modulating_bits[0])
            lfsr_modulation = 12'b0000_0000_0000;       // 0
        else 
            lfsr_modulation = 12'b1000_0000_0000;       // -MAX
    end

    /*
    * QPSK Modulation:
    * First component: BPSK(modulating_bits[0],cos)
    * Second component: BPSK(modulating_bits[1],sin)
    * Subtract the two and divide by sqrt(2) to ensure the result is >=1
    * Dividing by sqrt(2) is the same as multiplying by 724 and dividing by 1024, but the latter is more optimizable
    */
    always_ff @(posedge clk) begin
        qpsk_intermediate_val <= 724*(bpsk_cos_modulation-bpsk_sin_modulation);
        qpsk_modulation <= (qpsk_intermediate_val>>10);     // Divide by 1024
    end

    // Register output to avoid glitches
    always_ff @(posedge clk) begin
        modulated_wave_reg <= modulated_wave;
    end
    
endmodule

/*
 * 5-bit Linear Feedback Shift Register
 * Source: CPEN 311 Lab 5 Handout
 */
module lfsr_5bit 
    #( parameter INIT_VAL = 5'b00001) // Pseudo-random sequence initial value
    (
    clk,
    reset,
    rand_sequence   // Pseudo-random sequence
    );

    input logic clk;
    input logic reset;

    output logic [4:0] rand_sequence;   // Pseudo-random sequence

    logic [4:0] lfsr = INIT_VAL;    // Initial value

    assign rand_sequence = lfsr;

    // lfsr[4] register
    always_ff @(posedge clk) begin
        if (reset) lfsr[4] <= INIT_VAL[4];
        else
            lfsr[4] <= (lfsr[0] ^ lfsr[2]);
    end

    // lfsr[3] register
    always_ff @(posedge clk) begin
        if (reset) lfsr[3] <= INIT_VAL[3];
        else
            lfsr[3] <= lfsr[4];
    end

    // lfsr[2] register
    always_ff @(posedge clk) begin
        if (reset) lfsr[2] <= INIT_VAL[2];
        else
            lfsr[2] <= lfsr[3];
    end

    // lfsr[1] register
    always_ff @(posedge clk) begin
        if (reset) lfsr[1] <= INIT_VAL[1];
        else
            lfsr[1] <= lfsr[2];
    end

    // lfsr[0] register
    always_ff @(posedge clk) begin
        if (reset) lfsr[0] <= INIT_VAL[0];
        else
            lfsr[0] <= lfsr[1];
    end

endmodule



/*
* Clock Divider Module
* Generates a clock signal that is a fraction of the frequency of the input clock
* Source: Baud rate generator - CHU 8.2.2 pg 217
*/
module clk_divider #(parameter N = 32) (
    in_clk,
    reset,
    clk_limit,             
    divided_clk
    );     
    input  logic  in_clk;
    input  logic reset;
    input  logic [N-1:0] clk_limit;             // How many times in_clk will rise before divided_clk is flipped
    output logic divided_clk;
                           
    logic [N-1:0] r_reg, r_next;

    // Counter logic source: Mod-m counter - CHU 4.11 pg 95
    always_ff @(posedge in_clk, posedge reset) begin
        if (reset)
            r_reg <= 0;
        else
            r_reg <= r_next;
    end


    // Divided clock logic
    always_ff @(posedge in_clk, posedge reset) begin
        if (reset)
            divided_clk <= 0;
        else if (r_reg == (clk_limit-1))
            divided_clk <= ~divided_clk;     // Flip clock when limit is reached
    end


    // Next state logic MAKE THIS >= TO ACCOUNT FOR CHANGE IN LIMIT WHEN MOVING SWITCHES
    assign r_next = (r_reg>=(clk_limit-1)) ? 0 : r_reg + 1;

endmodule

/*
 * Clock-crossing logic from a slow to a fast clock
 * Source: CPEN 311 Lecture Notes: clock_skew_clock_domains
 */
module clk_crossing_slow_to_fast (
    lfsr_in,
    slow_clock,
    fast_clock,
    lfsr_fast_output);

    input logic [4:0] lfsr_in;
    input logic slow_clock;
    input logic fast_clock;
    output logic [4:0] lfsr_fast_output;

    logic in_ff_1;
    logic in_ff_2;

    logic out_ff_1;
    logic out_ff_2;

    logic inverted_fast_clock;
    logic enable_fast_circuit;

    logic [4:0] lfsr_slow;
    logic [4:0] lfsr_fast_from_slow;

    //enable_fast_circuit
    assign enable_fast_circuit = out_ff_2;

    //input to ff_1
    assign in_ff_1 = slow_clock;

    //connect output of first flip_flop to input of second flip_flop
    assign in_ff_2 = out_ff_1;

    //invert fast clock for flip flop circuit
    assign inverted_fast_clock = ~fast_clock;

    always_ff @ (posedge inverted_fast_clock) begin
    out_ff_1 <= in_ff_1;
    out_ff_2 <= in_ff_2;
    end

    always_ff @ (posedge slow_clock) begin
	    lfsr_slow <= lfsr_in;
    end

    always_ff @(posedge fast_clock) begin
	    if(enable_fast_circuit) 
		    lfsr_fast_from_slow <= lfsr_slow;
    end

    always_ff @(posedge fast_clock) begin
	    lfsr_fast_output <= lfsr_fast_from_slow;
    end


endmodule

/*
 * Clock-crossing logic from a fast to a slow clock
 * Source: CPEN 311 Lecture Notes: clock_skew_clock_domains
 */
module clk_crossing_fast_to_slow (
    fast_clk,
    fast_data_in,
    slow_clk,
    slow_data_out
    );
    
    // Fast clock domain
    input logic fast_clk;
    input logic [11:0] fast_data_in;
    
    // Slow clock domain
    input logic slow_clk;
    output logic [11:0] slow_data_out;

    logic sync_slow_clk;                // Q of sync_reg1
    logic inverted_fast_clk;
    logic data_reg_en;
    logic [11:0] reg1_q, reg3_q;

    assign inverted_fast_clk = ~fast_clk;
   
    // Reg1
    always_ff @ (posedge fast_clk) begin
	    reg1_q <= fast_data_in;
    end

    // Reg3
    always_ff @(posedge fast_clk) begin
	    if(data_reg_en) 
		    reg3_q <= reg1_q;
    end

    // Reg2
    always_ff @(posedge slow_clk) begin
	    slow_data_out <= reg3_q;
    end

    // Clock synchronizer logic
    always_ff @(posedge inverted_fast_clk) begin
	    sync_slow_clk <= slow_clk;
        data_reg_en <= sync_slow_clk;
    end
    
endmodule

`default_nettype wire