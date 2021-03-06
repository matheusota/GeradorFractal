LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.fixed_pkg.all;

ENTITY memory_control IS
	PORT(
		clk, rst, done	:IN STD_LOGIC;
		data_in					:BUFFER STD_LOGIC;
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
	
	COMPONENT VGA IS
	PORT(
		clk, rst	:IN STD_LOGIC;
		data  :IN STD_LOGIC;
		done  : IN STD_LOGIC;
		VGA_R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_HS, VGA_VS :OUT STD_LOGIC
	);
	END COMPONENT;
	
BEGIN
	data <= X"0000" WHEN data_in = '0' ELSE X"1111"; 
	data_mem <= "ZZZZZZZZZZZZZZZZ" WHEN done = '0' ELSE data;
	addr_out <= STD_LOGIC_VECTOR(addr_read) WHEN done = '0' ELSE STD_LOGIC_VECTOR(addr_write);
	vga0: VGA port map(clk, rst, done, data_in, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS); 
	
	PROCESS (clk, rst)
		VARIABLE data_aux : STD_LOGIC_VECTOR(15 downto 0);
	BEGIN
		IF (clk'EVENT and clk = '1') THEN
			IF (rst = '1') THEN
				addr_read <= (others => '0');
				addr_write <= (others => '0');
				WE_out <= '1';
				ub <= '0';
			ELSE
				IF data_in = '1' THEN HEX0(0) <= '1'; END IF;
				
				ub <= NOT ub;
				WE_out <= '1';
				--escreve na memoria
				IF done = '1' THEN
					WE_out <= '0';
					IF (addr_write > X"257FF") THEN
						addr_write <= (others => '0');
					ELSIF(ub = '1') THEN
						addr_write <= addr_write + 1;
					END IF;
					
					--alterna entre escrever na palavra de alta ou baixa
					IF (ub = '0') THEN
						UB_N <= '1';
						LB_N <= '0';
					ELSE
						UB_N <= '0';
						LB_N <= '1';
					END IF;
				
				--le da memoria
				ELSE
					--alterna entre ler da palavra alta ou baixa
					IF(ub = '1') THEN
						addr_read <= addr_read + 1;
						UB_N <= '0';
						LB_N <= '1';
						IF (addr_read > X"257FF") THEN
							addr_read <= (others => '0');
						END IF;
					ELSE
						UB_N <= '1';
						LB_N <= '0';
					END IF;
					
					--corrige caso a palavra lida seja alta
					IF(ub = '1') THEN
						data_aux := std_logic_vector((unsigned(data_mem) srl 8));
					END IF;
					
					--pinta de branco se n�o est� no conjunto
					IF (data_aux = X"0000") THEN
						data_vga <= '0';
					--pinta de preto se est� no conjunto
					ELSE
						data_vga <= '0';
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
END Behavior_memCtrl;