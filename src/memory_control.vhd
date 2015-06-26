LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.fixed_pkg.all;

ENTITY memory_control IS
	PORT(
		clk, rst, done	:IN STD_LOGIC;
		data_in					:IN STD_LOGIC;
		data_mem					:INOUT STD_LOGIC_VECTOR(15 downto 0);
		addr_out					:OUT STD_LOGIC_VECTOR(17 downto 0);
		WE_out					:OUT STD_LOGIC;
		LB_N					:OUT STD_LOGIC;
		UB_N					:OUT STD_LOGIC;
		VGA_R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		HEX0						:OUT STD_LOGIC_VECTOR(6 downto 0);
		VGA_HS, VGA_VS :OUT STD_LOGIC
	);
END memory_control;

ARCHITECTURE Behavior_memCtrl OF memory_control IS
	SIGNAL addr_read	:UNSIGNED(17 downto 0);
	SIGNAL addr_write	:UNSIGNED(17 downto 0);
	SIGNAL data_vga	: STD_LOGIC;
	SIGNAL data	: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL ub : STD_LOGIC;
	SIGNAL hcount, Vcount	: UNSIGNED(10 downto 0);
	signal produto : unsigned (21 downto 0);
	
	COMPONENT VGA IS
	PORT(
		clk, rst	:IN STD_LOGIC;
		data  :IN STD_LOGIC;
		VGA_R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		Hcount, Vcount	: BUFFER UNSIGNED(10 downto 0);
		VGA_HS, VGA_VS :OUT STD_LOGIC

	);
	END COMPONENT;
	
BEGIN
	data <= (others => data_in); 
	data_mem <= "ZZZZZZZZZZZZZZZZ" WHEN done = '0' ELSE data;
	addr_out <= STD_LOGIC_VECTOR(addr_read) WHEN done = '0' ELSE STD_LOGIC_VECTOR(addr_write);
	produto <= (hcount + vcount * 640)/2;
	WE_out <= not done;
	vga0: VGA port map(clk, rst, data_vga, VGA_R, VGA_G, VGA_B, hcount, vcount, VGA_HS, VGA_VS); 
	
	PROCESS (clk, rst)
		VARIABLE data_aux : STD_LOGIC_VECTOR(15 downto 0);
	BEGIN
		IF (clk'EVENT and clk = '1') THEN
			IF (rst = '1') THEN
				addr_read <= (others => '0');
				addr_write <= (others => '0');
				--WE_out <= '1';
				ub <= '0';
--				UB_N <= '1';
--				LB_N <= '0';
			ELSE
				
				--escreve na memoria
				IF done = '1' THEN
				    ub <= NOT ub;
					
					IF(ub = '1') THEN
						IF (addr_write >= 153600 - 1) THEN
							addr_write <= (others => '0');
						else
							addr_write <= addr_write + 1;
						end if;
					END IF;
					
					--alterna entre escrever na palavra de alta ou baixa
--					UB_N <= ub;
--					LB_N <= not ub;
					IF (ub = '0') THEN
						UB_N <= '1';
						LB_N <= '0';
					ELSE
						UB_N <= '0';
						LB_N <= '1';
					END IF;
				
				--le da memoria
				ELSE
					addr_read <= produto(17 downto 0);
					--alterna entre ler da palavra alta ou baixa
					UB_N <= not addr_read(0);
					LB_N <= addr_read(0);
					
					--corrige caso a palavra lida seja alta
					IF(addr_read(0) = '1') THEN
						data_aux := std_logic_vector((unsigned(data_mem) srl 8));
					ELSE
						data_aux := data_mem;
					END IF;
					
					--pinta de branco se não está no conjunto
					IF (data_aux = X"0000") THEN
						HEX0(0) <= '1'; 
						data_vga <= '1';
					--pinta de preto se está no conjunto
					ELSE
						HEX0(1) <= '1'; 
						data_vga <= '0';
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
END Behavior_memCtrl;