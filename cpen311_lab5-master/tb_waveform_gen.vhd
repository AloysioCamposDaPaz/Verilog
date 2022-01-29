library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity tb_waveform_gen is
end tb_waveform_gen;

architecture tb of tb_waveform_gen is
    signal tb_clk      : std_logic := '0';     -- Clock signal
    signal tb_reset    : std_logic;     -- Reset active low!!!
    signal tb_en       : std_logic;     -- Clock-enable
    
    signal tb_phase_inc   : std_logic_vector (31 downto 0);
    
    signal tb_sin_out     : std_logic_vector (11 downto 0);
    signal tb_cos_out     : std_logic_vector (11 downto 0);
    signal tb_squ_out     : std_logic_vector (11 downto 0);
    signal tb_saw_out     : std_logic_vector (11 downto 0);

begin
    -- connecting testbench signals with half_adder.vhd
    DUT : entity work.waveform_gen
        port map (
            clk         => tb_clk,      
            reset       => tb_reset,     
        
            en          => tb_en,       -- clock-enable     
            
            phase_inc   => tb_phase_inc,            -- NCO frequency control
            
            -- Output waveforms
            sin_out     => tb_sin_out,   
            cos_out     => tb_cos_out,   
            squ_out     => tb_squ_out,   
            saw_out     => tb_saw_out   
        );

    -- inputs
    tb_clk <= not tb_clk after 10 ps;
    tb_reset <= '0', '1' after 20 ps;   -- Begin with a reset
    tb_en <= '1';                       -- Always enabled
    tb_phase_inc <= "00000000100000110001001010110000";        -- About 10MHz        
                     
    end tb ;