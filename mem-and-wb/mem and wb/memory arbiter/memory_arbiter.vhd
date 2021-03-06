library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

use work.memory_arbiter_lib.all;

-- Do not modify the port map of this structure
entity memory_arbiter is
port (clk 	: in STD_LOGIC;
      reset : in STD_LOGIC;
      
			--Memory port #1
			addr1	: in NATURAL;
			data1	: inout STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 downto 0);
			re1		: in STD_LOGIC;
			we1		: in STD_LOGIC;
			busy1 	: out STD_LOGIC;
			
			--Memory port #2
			addr2	: in NATURAL;
			data2	: inout STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 downto 0);
			re2		: in STD_LOGIC;
			we2		: in STD_LOGIC;
			busy2 	: out STD_LOGIC
  );
end memory_arbiter;

architecture behavioral of memory_arbiter is

	--Main memory signals
	--Use these internal signals to interact with the main memory
	SIGNAL mm_address       : NATURAL                                       := 0;
	SIGNAL mm_we            : STD_LOGIC                                     := '0';
	SIGNAL mm_wr_done       : STD_LOGIC                                     := '0';
	SIGNAL mm_re            : STD_LOGIC                                     := '0';
	SIGNAL mm_rd_ready      : STD_LOGIC                                     := '0';
	SIGNAL mm_data          : STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 downto 0)   := (others => 'Z');
	SIGNAL mm_initialize    : STD_LOGIC                                     := '0';

	
	-- define the states
	type state_type is (idle, read1a, read1b, read2a, read2b, write1a, write1b, write2a, write2b, wait0);
	signal next_state, current_state: state_type;
	
begin

	--Instantiation of the main memory component (DO NOT MODIFY)
	main_memory : ENTITY work.Main_Memory
      GENERIC MAP (
		Num_Bytes_in_Word	=> NUM_BYTES_IN_WORD,
		Num_Bits_in_Byte 	=> NUM_BITS_IN_BYTE,
        Read_Delay        => 3, 
        Write_Delay       => 3
      )
	  
      PORT MAP (
        clk			=> clk,
        address     => mm_address,
        Word_Byte   => '1',
        we          => mm_we,
        wr_done     => mm_wr_done,
        re          => mm_re,
        rd_ready    => mm_rd_ready,
        data        => mm_data,
        initialize  => mm_initialize,
        dump        => '0'
      );
	
-- cocurrent process 1 : state registers
state_reg: process (clk, reset)
begin
	-- reset high
	if (reset = '1') then
		current_state <= idle;
	elsif rising_edge(clk) then 
		current_state <= next_state;
	end if;
end process;

-- cocurrent process 2 : combinational logic
comb_logic: process(current_state)
begin
	-- use case statement to show the state transition
	case current_state is
		when idle => 
			if re1 = '1' then
				next_state <= read1a;
			elsif we1 = '1' then
				next_state <= write1a;
			elsif re2 = '1' then
				next_state <= read2a;
			elsif we2 = '1' then
				next_state <= write2a;
			else
				next_state <= idle;
			end if;
		
		-- port 1 starts reading
		when read1a =>
			if mm_rd_ready = '1' then
				next_state <= read1b;
			else
				next_state <= read1a;
			end if;
		
		-- port 1 finishes reading
		when read1b =>
			if re1 = '1' then
				next_state <= read1a;
			elsif we1 = '1' then
				next_state <= wait0;
			elsif re2 = '1' then
				next_state <= read2a;
			elsif we2 = '1' then
				next_state <= wait0;
			else
				next_state <= idle;
			end if;
		
		-- port 1 starts writing
		when write1a =>
			if mm_wr_done = '1' then
				next_state <= write1b;
			else
				next_state <= write1a;
			end if;
		
		-- port 1 finishes writing
		when write1b =>
			if re1 = '1' then
				next_state <= read1a;
			elsif we1 = '1' then
				next_state <= write1a;
			elsif re2 = '1' then
				next_state <= read2a;
			elsif we2 = '1' then
				next_state <= write2a;
			else
				next_state <= idle;
			end if;		
		
		-- port 2 starts reading
		when read2a =>
			if mm_rd_ready = '1' then
				next_state <= read2b;
			else
				next_state <= read2a;
			end if;
		
		-- port 2 finishes reading
		when read2b =>
			if re1 = '1' then
				next_state <= read1a;
			elsif we1 = '1' then
				next_state <= wait0;
			elsif re2 = '1' then
				next_state <= read2a;
			elsif we2 = '1' then
				next_state <= wait0;
			else
				next_state <= idle;
			end if;
		
		-- port 2 starts writing
		when write2a =>
			if mm_wr_done = '1' then
				next_state <= write2b;
			else
				next_state <= write2a;
			end if;
		
		-- port 2 finishes writing
		when write2b =>
			if re1 = '1' then
				next_state <= read1a;
			elsif we1 = '1' then
				next_state <= write1a;
			elsif re2 = '1' then
				next_state <= read2a;
			elsif we2 = '1' then
				next_state <= write2a;
			else
				next_state <= idle;
			end if;	
		
		-- write after read wait 1 
		when wait0 =>
			if we1 = '1' then
				next_state <= write1a;
			elsif we2 = '1' then
				next_state <= write2a;
			else
				next_state <= idle;
			end if;
		
		when others =>
			next_state <= idle;
			
	end case;
end process;
	
output: process(current_state)
begin
	case current_state is
		when idle => 
			
		when read1a =>
			busy1 <= '1';
			mm_re <= re1;
			mm_data <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
			mm_address <= addr1;
		
		when read1b =>
			busy1 <= '0';
			data1 <= mm_data;
		
		when write1a =>
			busy1 <= '1';
			mm_we <= we1;
			mm_data <= data1;
			mm_address <= addr1;
			
		when write1b =>
		
		when read2a =>
			busy2 <= '1';
			mm_re <= re2;
			mm_data <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
			mm_address <= addr1;
		
		when read2b =>
			busy2 <= '0';
			data2 <= mm_data;
		
		when write2a =>
			busy2 <= '1';
			mm_we <= we1;
			mm_data <= data1;
			mm_address <= addr1;
			
		when write2b =>
			
			
		when wait0 =>
			busy1 <= '0';
			
		when others =>
		
	end case;	
end process;
	
	
end behavioral;