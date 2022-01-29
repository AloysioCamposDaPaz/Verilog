`default_nettype none
module tb_decrypt_encrypted();

logic reset;
logic clk;
logic start;
//dones from other FSMs
logic memory_done;
logic swap_done;
logic ROM_done;
logic RAM_done;
//memory reads
logic [7:0] MEM_read;
logic [7:0] encrypted_input_ROM;
//data from swap
logic [7:0] Si;
logic [7:0] Sj;
//selecting memory address output
logic swap_select_address;

//outputs
logic start_ROM;
logic start_RAM;
logic start_swap;
logic start_MEM;
logic write_op;
logic [7:0] addr_MEM;
logic [31:0] addr_RAM;
logic [31:0] addr_ROM;
logic done;
logic [7:0] decrypted_output_to_RAM;


decrypt_message DUT(.clk(clk), .reset(reset), .start(start), .memory_done(memory_done), .swap_done(swap_done), .ROM_done(ROM_done), .RAM_done(RAM_done), 
.MEM_read(MEM_read), .encrypted_input_ROM(encrypted_input_ROM), .Si(Si), .Sj(Sj), .swap_select_address(swap_select_address), .start_ROM(start_ROM), .start_RAM(start_RAM), .start_swap(start_swap), .start_MEM(start_MEM), .write_op(write_op), .addr_MEM(addr_MEM), .addr_RAM(addr_RAM), .addr_ROM(addr_ROM), .done(done), .decrypted_output_to_RAM(decrypted_output_to_RAM));

localparam [19:0] idle = 20'b000000_0000_0001_000000;
localparam [19:0] addi = 20'b000000_0000_0010_000000;
localparam [19:0] readSi = 20'b000000_0000_0100_000000;
localparam [19:0] wait_MEM_1 = 20'b000000_0000_1000_000000;
localparam [19:0] addj = 20'b000000_0001_0000_000010;
localparam [19:0] wait_swap = 20'b000000_0010_0000_000000;
localparam [19:0] readSiSj = 20'b000000_0100_0000_010001;
localparam [19:0] wait_MEM_2 = 20'b000000_1000_0000_000000;
localparam [19:0] read_ROM = 20'b000001_0000_0000_000100;
localparam [19:0] wait_ROM = 20'b000010_0000_0000_000000;
localparam [19:0] write_RAM = 20'b000100_0000_0000_001000;
localparam [19:0] wait_RAM = 20'b001000_0000_0000_000000;
localparam [19:0] add_k = 20'b010000_0000_0000_000000;
localparam [19:0] DONE = 20'b100000_0000_0000_100000;


 initial begin  
     forever begin
            clk = 0; #5;
            clk = 1; #5;
     end
 end

initial begin

        // Initial values
        reset = 0;
	Si = 8'b0;
	Sj = 8'b0;
	
	#10;
        // Begin with a reset
        reset = 1;
        #10;
        if(tb_decrypt_encrypted.DUT.state != idle ) begin $display ("Error"); $stop; end

        reset = 0;
        #10;
        if(tb_decrypt_encrypted.DUT.state != idle ) begin $display ("Error"); $stop; end

        #10;
        if(tb_decrypt_encrypted.DUT.state != idle ) begin $display ("Error"); $stop; end
	
	start = 1'b1;
	#10;
        if(tb_decrypt_encrypted.DUT.state != addi ) begin $display ("Error"); $stop; end

	start = 1'b0;
	#10;
        if(tb_decrypt_encrypted.DUT.state != readSi ) begin $display ("Error");$stop; end


	#10;
        if(tb_decrypt_encrypted.DUT.state != wait_MEM_1 ) begin $display ("Error"); $stop; end

	//stay in state if memory done not arrived
	#10;
        if(tb_decrypt_encrypted.DUT.state != wait_MEM_1 ) begin $display ("Error"); $stop; end

	memory_done = 1'b1;
	#10;
        if(tb_decrypt_encrypted.DUT.state != addj ) begin $display ("Error"); $stop; end

	memory_done = 1'b0;	
	#10;
        if(tb_decrypt_encrypted.DUT.state != wait_swap ) begin $display ("Error"); $stop; end
	
	//wait for swap done 
	#10;
        if(tb_decrypt_encrypted.DUT.state != wait_swap ) begin $display ("Error"); $stop; end

	swap_done = 1'b1;
	#10;
        if(tb_decrypt_encrypted.DUT.state != readSiSj ) begin $display ("Error"); $stop; end
	
	swap_done = 1'b0;
	#10;
        if(tb_decrypt_encrypted.DUT.state != wait_MEM_2 ) begin $display ("Error"); $stop; end
	//wait for memory
	#10;
        if(tb_decrypt_encrypted.DUT.state != wait_MEM_2 ) begin $display ("Error"); $stop; end
	
	memory_done = 1'b1;
	#10;
        if(tb_decrypt_encrypted.DUT.state != read_ROM ) begin $display ("Error"); $stop; end

	#10;
        if(tb_decrypt_encrypted.DUT.state != wait_ROM) begin $display ("Error");$stop; end
	//wait in ROM until rom_done arrives
	#10;
        if(tb_decrypt_encrypted.DUT.state != wait_ROM) begin $display ("Error"); $stop; end
	ROM_done = 1'b1;
	
	#10;
        if(tb_decrypt_encrypted.DUT.state != write_RAM) begin $display ("Error"); $stop; end
	ROM_done = 1'b0;

	#10;
        if(tb_decrypt_encrypted.DUT.state != wait_RAM) begin $display ("Error"); $stop; end

	//wait until ram_done arrives
	RAM_done = 1'b1;
	#10;
        if(tb_decrypt_encrypted.DUT.state != add_k) begin $display ("Error"); $stop; end
	RAM_done = 1'b0;

	#10;
        if(tb_decrypt_encrypted.DUT.state != DONE) begin $display ("Error"); $stop; end

	#10;
        if(tb_decrypt_encrypted.DUT.state != idle) begin $display ("Error"); $stop; end


$display ("PASSED ALL TESTS :D"); $stop;
end


endmodule


// Rod - Done
module tb_initialize_sram ();
    // Algorithm fsm
    logic s_clk;        
    logic s_start;      // To fsm
    logic s_reset;      // To fsm
    logic s_finished;     // From fsm
    logic s_write_sram;

    logic s_sram_fsm_start;
    logic s_sram_fsm_finished;
    logic [7:0] s_sram_addr;
    logic [7:0] s_sram_write_data;
    

    // Module instantiation
    initialize_sram DUT0 (
        .clk(s_clk),
        .reset(s_reset),
        .start(s_start),
        .finished(s_finished),

        // From/to sram fsm
        .sram_fsm_finished(s_sram_fsm_finished),
        .sram_fsm_start(s_sram_fsm_start),
        .write_sram(s_write_sram),
        .sram_addr(s_sram_addr),            // To memory
        .sram_write_data(s_sram_write_data)     // To memory
    );



    // Clock signal
    initial begin  
        forever begin
            s_clk = 0; #5;
            s_clk = 1; #5;
        end
    end

    initial begin  
        forever begin
            @(posedge s_clk);
            if (s_sram_fsm_start) begin
                #20; s_sram_fsm_finished = 1;
                #10; s_sram_fsm_finished = 0;
            end
        end
    end

    // Test script
    initial begin
    
        // Initial values
        s_start = 0;
        s_reset = 0;
        s_sram_fsm_finished = 0;

        // Begin with a reset
        s_reset = 1; #10;
        s_reset = 0; #10;

        // Start simulation
        s_start = 1'b1; #10;
        s_start = 1'b0; #10;
 
    end


endmodule

// Rod - Done
module tb_sram_swap_control ();
    
    logic s_clk; 
    logic s_reset;
    logic s_start;

    logic s_finished;
    logic s_addr_select;          
    logic s_data_select;          
    logic s_sram_write;    

    logic [7:0] s_si_reg;
    logic [7:0] s_sj_reg;        
    
    // From/To memory_control fsm
    logic s_sram_fsm_finished;
    logic [7:0] s_read_data;                  // Data from sram (simulated)
    logic s_sram_fsm_start;

    logic [7:0] s_write_data;                 // Data to be written to sram

    sram_swap_control DUT0 (
        .clk(s_clk), 
        .reset(s_reset),
        .start(s_start),
        .finished(s_finished),
        .addr_select(s_addr_select),           
        .data_select(s_data_select),          
        .sram_write(s_sram_write),
        .sram_fsm_finished(s_sram_fsm_finished),
        .read_data(s_read_data),
        .sram_fsm_start(s_sram_fsm_start),
        .write_data(s_write_data),
        .si_reg(s_si_reg),
        .sj_reg(s_sj_reg)
    );


    // Clock signal
    initial begin  
        forever begin
            s_clk = 0; #5;
            s_clk = 1; #5;
        end
    end


    initial begin  
        forever begin
            @(posedge s_clk);
            if (s_sram_fsm_start) begin
                #20; s_sram_fsm_finished = 1;
                #10; s_sram_fsm_finished = 0;
                s_read_data = s_read_data + 8'h07;
            end
        end
    end


    // Test script
    initial begin
    
        // Initial values
        s_start = 0;
        s_reset = 0;
        s_read_data = 8'h0A;     // Test value
        s_sram_fsm_finished = 0;

        // Begin with a reset
        s_reset = 1; #10;
        s_reset = 0; #10;

        // Start simulation
        s_start = 1'b1; #10;
        s_start = 1'b0; #10;


    end

endmodule

// Aloy
module tb_shuffle_sram ();

    logic tb_clk;
    logic tb_reset;
    logic tb_start_task2;
    logic [23:0] tb_secret_key = 24'h000249;
    logic tb_done;

    // sram_control
    logic tb_memory_finish;
    logic [7:0] tb_memory_data;      //coming from flash controller
    logic tb_sram_control_start;            // changed from start_mem
    logic tb_sram_write_op;   
    logic [7:0] tb_address;
    logic [7:0] tb_sram_write_data;     // Passes swap data to sram controller

    // swap_control_fsm
    logic tb_swap_done;
    logic tb_addr_select;
    logic tb_swap_start_mem;             // From swap to start sram_control
    logic tb_swap_sram_write;            // write_op
    logic [7:0] tb_swap_write_data;
    logic tb_start_swap;

    control_swap DUT0 (
        .clk(tb_clk),
        .reset(tb_reset),
        .start_task2(tb_start_task2),
        .secret_key(tb_secret_key),              
        .done(tb_done),

        .memory_finish(tb_memory_finish),
        .memory_data(tb_memory_data),      
        .sram_control_start(tb_sram_control_start),           
        .sram_write_op(tb_sram_write_op),   
        .address(tb_address),
        .sram_write_data(tb_sram_write_data),

        .swap_done(tb_swap_done),
        .addr_select(tb_addr_select),
        .swap_start_mem(tb_swap_start_mem),             
        .swap_sram_write(tb_swap_sram_write),        
        .swap_write_data(tb_swap_write_data),
        .start_swap(tb_start_swap)  
    );
    


    initial begin  
        forever begin
            tb_clk = 0; #5;
            tb_clk = 1; #5;
        end
    end

    initial begin  
        forever begin
            @(posedge tb_clk);
            if (tb_sram_control_start) begin
                #20; tb_memory_finish = 1;
                #10; tb_memory_finish = 0;
                tb_memory_data = tb_memory_data + 8'h07;
            end
            if (tb_start_swap) begin
                #20; tb_swap_done = 1;
                #10; tb_swap_done = 0;
            end
        end
    end

    initial begin

        // Initial values
        tb_reset = 0;
        tb_start_task2 = 0;

        tb_memory_finish = 0;
        tb_memory_data = 8'h05;

        tb_swap_done = 0;
        tb_swap_done = 0;
        tb_addr_select = 0;
        tb_swap_start_mem = 0;
        tb_swap_sram_write = 0;
        tb_swap_write_data = 8'b0;
        
        // Begin with a reset
        tb_reset = 1;
        #10;
        
        //test staying in idle
        tb_reset = 0;
        #10;

        //test going to read_ram
        tb_start_task2 = 1;
        #10;

        //test going to wait_read
        tb_start_task2 = 0;
        #10;
    end
        
endmodule

// Aloy
module tb_adder_swap ();

        //inputs
        logic tb_clk;
        logic tb_reset;
        logic tb_start_task2;
        logic tb_memory_finish;
        logic tb_swap_done;
        logic [7:0] tb_memory_data; //coming from flash controller
        logic [23:0] tb_secret_key;

        //outputs
        logic tb_write_op;
        logic tb_start_mem;
        logic tb_start_swap;
        logic [7:0] tb_address;
        logic tb_done;

        control_swap DUT (.memory_data(tb_memory_data), .secret_key(tb_secret_key), .clk(tb_clk), .reset(tb_reset), .start_task2(tb_start_task2), .memory_finish(tb_memory_finish), .swap_done(tb_swap_done), .write_op(tb_write_op), .start_mem(tb_start_mem), .start_swap(tb_start_swap), .address(tb_address), .done(tb_done));

        localparam [10:0] idle = 11'b0000_0000001;
        localparam [10:0] read_ram = 11'b1100_0000010;
        localparam [10:0] wait_read = 11'b0000_0000100;
        localparam [10:0] add_all = 11'b0010_0001000;
        localparam [10:0] wait_done = 11'b0000_0010000;
        localparam [10:0] done_encoding = 11'b0001_0100000;
        localparam [10:0] add_i = 11'b0000_1000000;

        initial begin  
        forever begin
                tb_clk = 0; #5;
                tb_clk = 1; #5;
        end
        end

        initial begin

                // Initial values
                tb_reset = 0;
                tb_start_task2 = 0;
                tb_memory_finish = 0;
                tb_swap_done = 0;
                
                #10;
                // Begin with a reset
                tb_reset = 1;
                #10;
                if(tb_adder_swap.DUT.state != idle ) begin $display ("Error"); $stop; end
                if(tb_address != 8'b0 ) begin $display ("Error"); $stop; end
                if(tb_write_op != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_mem != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_swap != 0 ) begin $display ("Error"); $stop; end
                if(tb_done != 0 ) begin $display ("Error"); $stop; end

                //test staying in idle
                tb_reset = 0;
                #10;
                if(tb_adder_swap.DUT.state != idle ) begin $display ("Error"); $stop; end
                if(tb_address != 8'b0 ) begin $display ("Error"); $stop; end
                if(tb_write_op != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_mem != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_swap != 0 ) begin $display ("Error"); $stop; end
                if(tb_done != 0 ) begin $display ("Error"); $stop; end


                //test going to read_ram
                tb_start_task2 = 1;
                #10;
                if(tb_adder_swap.DUT.state != read_ram ) begin $display ("Error"); $stop; end
                if(tb_address != 8'b0 ) begin $display ("Error"); $stop; end
                if(tb_write_op != 1 ) begin $display ("Error"); $stop; end
                if(tb_start_mem != 1 ) begin $display ("Error"); $stop; end
                if(tb_start_swap != 0 ) begin $display ("Error"); $stop; end
                if(tb_done != 0 ) begin $display ("Error"); $stop; end


                //test going to wait_read
                tb_start_task2 = 0;
                #10;
                if(tb_adder_swap.DUT.state != wait_read ) begin $display ("Error"); $stop; end
                if(tb_address != 8'b0 ) begin $display ("Error"); $stop; end
                if(tb_write_op != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_mem != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_swap != 0 ) begin $display ("Error"); $stop; end
                if(tb_done != 0 ) begin $display ("Error"); $stop; end


                //test staying in wait_read
                #10;
                if(tb_adder_swap.DUT.state != wait_read ) begin $display ("Error"); $stop; end
                if(tb_address != 8'b0 ) begin $display ("Error"); $stop; end
                if(tb_write_op != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_mem != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_swap != 0 ) begin $display ("Error"); $stop; end
                if(tb_done != 0 ) begin $display ("Error"); $stop; end

                //test going to add_all
                tb_memory_finish = 1;
                #10;
                if(tb_adder_swap.DUT.state != add_all ) begin $display ("Error"); $stop; end
                if(tb_address != 8'b0 ) begin $display ("Error"); $stop; end
                if(tb_write_op != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_mem != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_swap != 1 ) begin $display ("Error"); $stop; end
                if(tb_done != 0 ) begin $display ("Error"); $stop; end

                //test going to wait_done
                tb_memory_finish = 0;
                #10;
                if(tb_adder_swap.DUT.state != wait_done ) begin $display ("Error"); $stop; end
                if(tb_address != 8'b0 ) begin $display ("Error"); $stop; end
                if(tb_write_op != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_mem != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_swap != 0 ) begin $display ("Error"); $stop; end
                if(tb_done != 0 ) begin $display ("Error"); $stop; end


                //test going to add_i
                tb_swap_done = 1;
                #10;
                if(tb_adder_swap.DUT.state != add_i ) begin $display ("Error"); $stop; end
                if(tb_address != 8'b0 ) begin $display ("Error"); $stop; end
                if(tb_write_op != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_mem != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_swap != 0 ) begin $display ("Error"); $stop; end
                if(tb_done != 0 ) begin $display ("Error"); $stop; end


                //test going to idle
                tb_swap_done = 0;
                #10;
                if(tb_adder_swap.DUT.state != read_ram ) begin $display ("Error"); $stop; end
                if(tb_address != 8'b0 ) begin $display ("Error"); $stop; end
                if(tb_write_op != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_mem != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_swap != 0 ) begin $display ("Error"); $stop; end
                if(tb_done != 0 ) begin $display ("Error"); $stop; end

                //test reaching done state
                tb_swap_done = 1;
                tb_memory_finish = 1;

                #50000;
                if(tb_adder_swap.DUT.state != done_encoding ) begin $display ("Error"); $stop; end
                if(tb_address != 8'b1111_1111 ) begin $display ("Error"); $stop; end
                if(tb_write_op != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_mem != 0 ) begin $display ("Error"); $stop; end
                if(tb_start_swap != 0 ) begin $display ("Error"); $stop; end
                if(tb_done != 1 ) begin $display ("Error"); $stop; end


        $display ("PASSED ALL TESTS :DDDD"); $stop;

                

        end
        
endmodule

// Aloy
module tb_decrypt_encrypted();

    logic reset;
    logic clk;
    logic start;
    //dones from other FSMs
    logic memory_done;
    logic swap_done;
    logic ROM_done;
    logic RAM_done;
    //memory reads
    logic [7:0] MEM_read;
    logic [7:0] encrypted_input_ROM;
    //data from swap
    logic [7:0] Si;
    logic [7:0] Sj;
    //selecting memory address output
    logic swap_select_address;

    //outputs
    logic start_ROM;
    logic start_RAM;
    logic start_swap;
    logic start_MEM;
    logic write_op;
    logic [7:0] addr_MEM;
    logic [31:0] addr_RAM;
    logic [31:0] addr_ROM;
    logic done;
    logic [7:0] decrypted_output_to_RAM;


    decrypt_message DUT(.clk(clk), .reset(reset), .start(start), .memory_done(memory_done), .swap_done(swap_done), .ROM_done(ROM_done), .RAM_done(RAM_done), 
    .MEM_read(MEM_read), .encrypted_input_ROM(encrypted_input_ROM), .Si(Si), .Sj(Sj), .swap_select_address(swap_select_address), .start_ROM(start_ROM), .start_RAM(start_RAM), .start_swap(start_swap), .start_MEM(start_MEM), .write_op(write_op), .addr_MEM(addr_MEM), .addr_RAM(addr_RAM), .addr_ROM(addr_ROM), .done(done), .decrypted_output_to_RAM(decrypted_output_to_RAM));

    localparam [19:0] idle = 20'b000000_0000_0001_000000;
    localparam [19:0] addi = 20'b000000_0000_0010_000000;
    localparam [19:0] readSi = 20'b000000_0000_0100_000000;
    localparam [19:0] wait_MEM_1 = 20'b000000_0000_1000_000000;
    localparam [19:0] addj = 20'b000000_0001_0000_000010;
    localparam [19:0] wait_swap = 20'b000000_0010_0000_000000;
    localparam [19:0] readSiSj = 20'b000000_0100_0000_010001;
    localparam [19:0] wait_MEM_2 = 20'b000000_1000_0000_000000;
    localparam [19:0] read_ROM = 20'b000001_0000_0000_000100;
    localparam [19:0] wait_ROM = 20'b000010_0000_0000_000000;
    localparam [19:0] write_RAM = 20'b000100_0000_0000_001000;
    localparam [19:0] wait_RAM = 20'b001000_0000_0000_000000;
    localparam [19:0] add_k = 20'b010000_0000_0000_000000;
    localparam [19:0] DONE = 20'b100000_0000_0000_100000;


    initial begin  
        forever begin
                clk = 0; #5;
                clk = 1; #5;
        end
    end

    initial begin

            // Initial values
            reset = 0;
        Si = 8'b0;
        Sj = 8'b0;
        
        #10;
            // Begin with a reset
            reset = 1;
            #10;
            if(tb_decrypt_encrypted.DUT.state != idle ) begin $display ("Error"); $stop; end

            reset = 0;
            #10;
            if(tb_decrypt_encrypted.DUT.state != idle ) begin $display ("Error"); $stop; end

            #10;
            if(tb_decrypt_encrypted.DUT.state != idle ) begin $display ("Error"); $stop; end
        
        start = 1'b1;
        #10;
            if(tb_decrypt_encrypted.DUT.state != addi ) begin $display ("Error"); $stop; end

        start = 1'b0;
        #10;
            if(tb_decrypt_encrypted.DUT.state != readSi ) begin $display ("Error");$stop; end


        #10;
            if(tb_decrypt_encrypted.DUT.state != wait_MEM_1 ) begin $display ("Error"); $stop; end

        //stay in state if memory done not arrived
        #10;
            if(tb_decrypt_encrypted.DUT.state != wait_MEM_1 ) begin $display ("Error"); $stop; end

        memory_done = 1'b1;
        #10;
            if(tb_decrypt_encrypted.DUT.state != addj ) begin $display ("Error"); $stop; end

        memory_done = 1'b0;	
        #10;
            if(tb_decrypt_encrypted.DUT.state != wait_swap ) begin $display ("Error"); $stop; end
        
        //wait for swap done 
        #10;
            if(tb_decrypt_encrypted.DUT.state != wait_swap ) begin $display ("Error"); $stop; end

        swap_done = 1'b1;
        #10;
            if(tb_decrypt_encrypted.DUT.state != readSiSj ) begin $display ("Error"); $stop; end
        
        swap_done = 1'b0;
        #10;
            if(tb_decrypt_encrypted.DUT.state != wait_MEM_2 ) begin $display ("Error"); $stop; end
        //wait for memory
        #10;
            if(tb_decrypt_encrypted.DUT.state != wait_MEM_2 ) begin $display ("Error"); $stop; end
        
        memory_done = 1'b1;
        #10;
            if(tb_decrypt_encrypted.DUT.state != read_ROM ) begin $display ("Error"); $stop; end

        #10;
            if(tb_decrypt_encrypted.DUT.state != wait_ROM) begin $display ("Error");$stop; end
        //wait in ROM until rom_done arrives
        #10;
            if(tb_decrypt_encrypted.DUT.state != wait_ROM) begin $display ("Error"); $stop; end
        ROM_done = 1'b1;
        
        #10;
            if(tb_decrypt_encrypted.DUT.state != write_RAM) begin $display ("Error"); $stop; end
        ROM_done = 1'b0;

        #10;
            if(tb_decrypt_encrypted.DUT.state != wait_RAM) begin $display ("Error"); $stop; end

        //wait until ram_done arrives
        RAM_done = 1'b1;
        #10;
            if(tb_decrypt_encrypted.DUT.state != add_k) begin $display ("Error"); $stop; end
        RAM_done = 1'b0;

        #10;
            if(tb_decrypt_encrypted.DUT.state != DONE) begin $display ("Error"); $stop; end

        #10;
            if(tb_decrypt_encrypted.DUT.state != idle) begin $display ("Error"); $stop; end


    $display ("PASSED ALL TESTS :D"); $stop;
    end


endmodule

// Rod - Done
module tb_decrypted_ram_control ();

    logic s_clk;
    logic s_reset;
    logic s_start;
    logic [7:0] s_write_data_in;
    logic [4:0] s_mem_addr_in;
    logic s_finished;
    logic s_data_invalid;
    logic s_write_enable;
    logic [7:0] s_write_data_out;    
    logic [4:0] s_mem_addr_out;

    // Module instantiation
    decrypted_ram_control DUT0 (
        .clk(s_clk), 
        .reset(s_reset),
        .start(s_start),
        .write_data_in(s_write_data_in),
        .mem_addr_in(s_mem_addr_in),

        .finished(s_finished),
        .data_invalid(s_data_invalid),
        .write_enable(s_write_enable),
        .write_data_out(s_write_data_out),    
        .mem_addr_out(s_mem_addr_out)      
    );

    // Clock signal
    initial begin  
        forever begin
            s_clk = 0; #5;
            s_clk = 1; #5;
        end
    end

    // Test script
    initial begin
    
        // Initial values
        s_start = 0;
        s_reset = 0;
        s_write_data_in = 8'h00;
        s_mem_addr_in = 5'h0A; // Test value

        // Begin with a reset
        s_reset = 1;
        #10;
        s_reset = 0;
        #10;


        // Test writing a valid character (100)
        s_write_data_in = 8'd100;
        s_start = 1'b1; #10;
        s_start = 1'b0; #40;
        if(tb_decrypted_ram_control.DUT0.data_invalid != 0) $display ("Error: Failed char 100"); // Expected valid

        // Test edge case 97
        s_write_data_in = 8'd097;
        s_start = 1'b1; #10;
        s_start = 1'b0; #40;
        if(tb_decrypted_ram_control.DUT0.data_invalid != 0) $display ("Error: Failed char 97"); // Expected valid

        // Test edge case 96
        s_write_data_in = 8'd096;
        s_start = 1'b1; #10;
        s_start = 1'b0; #50;
        if(tb_decrypted_ram_control.DUT0.data_invalid != 1) $display ("Error: Failed char 96"); // Expected invalid

        // Test edge case 122
        // Test edge case 123
        // Test space character 32
        // Test random character 15


        $display ("Success: Module passed all tests");
 	    $stop;

    end

endmodule

// Rod - Done
module tb_master_fsm ();

    logic s_clk;
	logic s_reset;
	logic s_start;
    logic s_finished;

    // Initialize SRAM FSM Signals
    logic s_initialize_finished;
    logic s_initialize_start;             
    logic s_initialize_reset;
    
    // Shuffle SRAM FSM Signals
    logic s_shuffle_finished;
    logic s_shuffle_start;             
    logic s_shuffle_reset;

    // Compute message FSM  Signals
    logic s_compute_finished;
	logic s_data_invalid;
    logic s_compute_start;
    logic s_compute_reset;

    // swap_control and sram_control Reset Signals
    logic s_swap_reset;
    logic s_sram_reset;
	logic s_decr_ram_reset;
	logic s_encr_rom_reset;

    // Control mux signals
    logic [1:0] s_control_select;

	// Key counter
	logic s_max_key;
	logic s_en_next_key;
	logic s_reset_key;
	logic s_key_not_found;


    // Module instantiation
    master_fsm DUT0 (
        .clk(s_clk),
        .reset(s_reset),
        .start(s_start),
        .finished(s_finished),

        .initialize_finished(s_initialize_finished),
        .initialize_start(s_initialize_start),             
        .initialize_reset(s_initialize_reset),
        
        .shuffle_finished(s_shuffle_finished),
        .shuffle_start(s_shuffle_start),             
        .shuffle_reset(s_shuffle_reset),

        .compute_finished(s_compute_finished),
        .data_invalid(s_data_invalid),
        .compute_start(s_compute_start),
        .compute_reset(s_compute_reset),

        .swap_reset(s_swap_reset),
        .sram_reset(s_sram_reset),
        .decr_ram_reset(s_decr_ram_reset),
        .encr_rom_reset(s_encr_rom_reset),

        .control_select(s_control_select),

        .max_key(s_max_key),
        .en_next_key(s_en_next_key),
        .reset_key(s_reset_key),
        .key_not_found(s_key_not_found)
    );


    // Clock signal
    initial begin  
        forever begin
            s_clk = 0; #5;
            s_clk = 1; #5;
        end
    end


    initial begin  
        forever begin
            @(posedge s_clk);
            if (s_initialize_start) begin
                #20; s_initialize_finished = 1;
                #10; s_initialize_finished = 0;
            end

            if (s_shuffle_start) begin
                #20; s_shuffle_finished = 1;
                #10; s_shuffle_finished = 0;
            end

            if (s_compute_start) begin
                #20; s_compute_finished = 1;
                #10; s_compute_finished = 0;
            end
        end
    end

        // Test script
    initial begin
    
        // Initial values
        s_start = 0;
        s_reset = 0;
        s_initialize_finished = 0;
        s_shuffle_finished = 0;
        s_compute_finished = 0;
        s_data_invalid = 0;
        s_max_key = 0;

        // Begin with a reset
        s_reset = 1; #10;
        s_reset = 0; #10;

        // Start simulation
        s_start = 1'b1; #10;
        s_start = 1'b0;

        // Simulate end of keyspace
        s_max_key = 1;


        // Wrong key
        #70;
        s_data_invalid = 1; #10;
        s_data_invalid = 0;



    end


endmodule