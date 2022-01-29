module tb_lfsr_5bit ();
    logic tb_clk;
    logic tb_reset;

    logic [4:0] tb_rand_sequence;


    lfsr_5bit DUT0 (
    .clk(tb_clk),
    .reset(tb_reset),
    .rand_sequence(tb_rand_sequence)
    );


    initial begin  
        forever begin
            tb_clk = 0; #5;
            tb_clk = 1; #5;
        end
    end

    initial begin

        // Initial values
        tb_reset = 0;
        #10;            // Check initial values

        // Begin with a reset
        tb_reset = 1; #10;
        tb_reset = 0; #10;


    end

endmodule