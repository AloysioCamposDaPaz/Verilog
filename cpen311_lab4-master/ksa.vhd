--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

-- Constants
package lab4_package is
	constant num : integer := 8;	-- data width
	constant max : integer := 255;	-- max counter value

end lab4_package;

use work.lab4_package.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ksa is
	port (
		CLOCK_50            : in  std_logic;  -- Clock pin
		KEY                 : in  std_logic_vector(3 downto 0);  -- push button switches
		SW                 	: in  std_logic_vector(9 downto 0);  -- slider switches
		LEDR : out std_logic_vector(9 downto 0);  -- red lights
		HEX0 : out std_logic_vector(6 downto 0);
		HEX1 : out std_logic_vector(6 downto 0);
		HEX2 : out std_logic_vector(6 downto 0);
		HEX3 : out std_logic_vector(6 downto 0);
		HEX4 : out std_logic_vector(6 downto 0);
		HEX5 : out std_logic_vector(6 downto 0)
	);
end ksa;

architecture rtl of ksa is -- here we instantiate components and signals
	-- the name of the component is how it will be called inside "begin" afterwards
	
	-- clock and reset signals  
	signal clk_50M, reset_n : std_logic;

	component SevenSegmentDisplayDecoder is
		port (
			ssOut 	: out std_logic_vector (6 downto 0);
			nIn 	: in std_logic_vector (3 downto 0)
		);
		end component;
      	

	--instantiate memory as well
	--notice that all the ports are as defined in the original module (the outputs/inputs of the module)
	component s_memory is
	   port (
			address	: in std_logic_vector (7 downto 0);
			clock	: in std_logic; -- was :='1'
			data	: in std_logic_vector (7 downto 0);
			wren	: in std_logic;
			q		: out std_logic_vector (7 downto 0)
		);
	 end component;

	-- RAM Block to store decrypted message 
	component ram IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		clock		: IN STD_LOGIC;  --was := '1';
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)	
	);
	END component;	

	-- ROM block to store encrypted message
	component rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		clock		: IN STD_LOGIC ; -- := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	END component;

	-- Includes all logic and internal modules in Verilog
	component top_level is
		port (
			clk			: in std_logic;
			reset		: in std_logic;	
			start		: in std_logic;		

			sram_read_data		: in std_logic_vector (7 downto 0);
			sram_write_enable	: out std_logic;
			sram_write_data		: out std_logic_vector (7 downto 0);
			sram_addr			: out std_logic_vector (7 downto 0);

			ram_addr				: out std_logic_vector(4 downto 0);
			ram_write_data			: out std_logic_vector(7 downto 0);
			ram_write_enable 		: out std_logic;
			ram_read_data 			: in std_logic_vector(7 downto 0);	
		
			rom_addr 				: out std_logic_vector(4 downto 0);			
			rom_read_data			: in std_logic_vector(7 downto 0);

			-- Signals to LEDs
			key_not_found			: out std_logic ;
			key_found				: out std_logic	;
		
			-- Signals to HEX 
			secret_key_0 : out std_logic_vector(3 downto 0);
			secret_key_1 : out std_logic_vector(3 downto 0);
			secret_key_2 : out std_logic_vector(3 downto 0);
			secret_key_3 : out std_logic_vector(3 downto 0);
			secret_key_4 : out std_logic_vector(3 downto 0);
			secret_key_5 : out std_logic_vector(3 downto 0)
		);
	end component;
		


	-- Signals for sseg in
	signal number_sseg0 : std_logic_vector (3 downto 0);
	signal number_sseg1 : std_logic_vector (3 downto 0);
	signal number_sseg2 : std_logic_vector (3 downto 0);
	signal number_sseg3 : std_logic_vector (3 downto 0);
	signal number_sseg4 : std_logic_vector (3 downto 0);
	signal number_sseg5 : std_logic_vector (3 downto 0);

	--create signals to connect with S-RAM block
	signal sram_addr				: std_logic_vector (7 downto 0) ;
	signal sram_write_data  		: std_logic_vector (7 downto 0);
	signal sram_write_enable  		: std_logic;
	signal sram_read_data			: std_logic_vector (7 downto 0);

	signal ram_addr					: std_logic_vector(4 downto 0);
	signal ram_write_data			: std_logic_vector(7 downto 0);
	signal ram_write_enable 		: std_logic;
	signal ram_read_data 			: std_logic_vector(7 downto 0);	

	signal rom_addr 				: std_logic_vector(4 downto 0);			
	signal rom_read_data			: std_logic_vector(7 downto 0);


	-- LED signals
	signal success_LED 				: std_logic;
	signal fail_LED 				: std_logic;

	-- Start
	signal start_decryption 		: std_logic;

	
 
begin -- here is where we say what the logic does and how ports are connected

    clk_50M <= CLOCK_50;
    reset_n <= KEY(3);
	start_decryption <= not KEY(2);
	LEDR(9) <= success_LED;
	LEDR(0) <= fail_LED;

	
	-- Seven segment decoders (one for each HEX display)
	sseg_display_dec0 : SevenSegmentDisplayDecoder port map 
	(
		ssOUt => HEX0,
		nIn => number_sseg0
	);

	sseg_display_dec1 : SevenSegmentDisplayDecoder port map 
	(
		ssOUt => HEX1,
		nIn => number_sseg1
	);

	sseg_display_dec2 : SevenSegmentDisplayDecoder port map 
	(
		ssOUt => HEX2,
		nIn => number_sseg2
	);

	sseg_display_dec3 : SevenSegmentDisplayDecoder port map 
	(
		ssOUt => HEX3,
		nIn => number_sseg3
	);

	sseg_display_dec4 : SevenSegmentDisplayDecoder port map 
	(
		ssOUt => HEX4,
		nIn => number_sseg4
	);

	sseg_display_dec5 : SevenSegmentDisplayDecoder port map 
	(
		ssOUt => HEX5,
		nIn => number_sseg5
	);

	-- SRAM
	s_memory_instance : s_memory port map
	(
		address	=> sram_addr,
		clock	=> clk_50M,
		data	=> sram_write_data,
		wren	=> sram_write_enable,
		q		=> sram_read_data
	);
	 
	-- Decrypted RAM
	ram_instance : ram port map
	(
		address	=> ram_addr,
		clock		=> clk_50M,
		data		=> ram_write_data,
		wren		=> ram_write_enable,
		q			=> ram_read_data	
	);	

	-- Encrypted ROM
	rom_instance : rom port map
	(
		address	=> rom_addr,
		clock		=> clk_50M,
		q			=> rom_read_data
	);

	top_level_instance : top_level port map
	(
		clk					=> clk_50M, 
		reset				=> '0',
		start				=> start_decryption,
	
		-- SRAM Signals
		sram_read_data		=> sram_read_data,
		sram_write_enable	=> sram_write_enable,
		sram_write_data		=> sram_write_data,
		sram_addr			=> sram_addr,

		-- RAM Signals
		ram_addr 			=> ram_addr, 	
		ram_write_data 		=> ram_write_data,	
		ram_write_enable	=> ram_write_enable,
		ram_read_data 		=> ram_read_data,
	
		-- ROM Signals
		rom_addr 			=> rom_addr,	
		rom_read_data		=> rom_read_data,

		-- LED Signals
		key_not_found		=> fail_LED,
		key_found			=> success_LED,
	
		-- Signals to HEX 
		secret_key_0 		=>	number_sseg0,
		secret_key_1 		=>	number_sseg1,
		secret_key_2 		=>	number_sseg2,
		secret_key_3 		=>	number_sseg3,
		secret_key_4 		=>	number_sseg4,
		secret_key_5 		=>	number_sseg5	
	);
	 
end RTL;