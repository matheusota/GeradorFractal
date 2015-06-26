LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY VGA IS
	generic (
		NUM_HORZ_PIXELS : natural := 640;  -- Number of horizontal pixels
		NUM_VERT_PIXELS : natural := 480);  -- Number of vertical pixels
	PORT(
		clk, rst	:IN STD_LOGIC;
		data  :IN STD_LOGIC;
		done  :IN STD_LOGIC;
		VGA_R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_HS, VGA_VS :OUT STD_LOGIC
	);
END ENTITY VGA;
--640 656 720 800 480 481 484 497 -HSync +Vsync

ARCHITECTURE Behavior_VGA OF VGA IS
	SIGNAL Hcount	:UNSIGNED(10 downto 0);
	SIGNAL Vcount	:UNSIGNED(10 downto 0);
	SIGNAL int_hs, int_vs :STD_LOGIC;
	CONSTANT Hactive	:UNSIGNED(10 downto 0)	:= to_unsigned(640, 11);
	CONSTANT Hsyncs	:UNSIGNED(10 downto 0)	:= to_unsigned(664, 11);
	CONSTANT Hsynce	:UNSIGNED(10 downto 0)	:= to_unsigned(704, 11);
	CONSTANT Htotal	:UNSIGNED(10 downto 0)	:= to_unsigned(832, 11);
	CONSTANT Vactive	:UNSIGNED(9 downto 0)	:= to_unsigned(480, 10);
	CONSTANT Vsyncs	:UNSIGNED(9 downto 0)	:= to_unsigned(489, 10);
	CONSTANT Vsynce	:UNSIGNED(9 downto 0)	:= to_unsigned(492, 10);
	CONSTANT Vtotal	:UNSIGNED(9 downto 0)	:= to_unsigned(520, 10);
BEGIN
	VGA_HS <= int_hs;
	VGA_VS <= int_vs;
	PROCESS(clk, rst)
	BEGIN
		IF (clk'EVENT AND clk = '1') THEN
			IF (rst = '1') THEN
				Hcount <= "00000000000";
				Vcount <= "00000000000";
				int_hs <= '1';
				int_vs <= '1';
			ELSE
				--conta linha e coluna da imagem
				IF (Hcount < Htotal) THEN
					Hcount <= Hcount + 1;
				ELSE
					Hcount <= "00000000000";
					IF (Vcount < Vtotal) THEN
						Vcount <= Vcount + 1;
					ELSE
						Vcount <= "00000000000";
					END IF;
				END IF;
				
				--entre syncs e synce o sinal de sincronização deve estar ativo
				IF((Hcount > Hsyncs) AND (Hcount < Hsynce)) THEN
					int_hs <= '0';
				ELSE
					int_hs <= '1';
				END IF;
				IF((Vcount > Vsyncs) AND (Vcount < Vsynce)) THEN
					int_vs <= '0';
				ELSE
					int_vs <= '1';
				END IF;
				
				--o sinal RGB deve ir para 0 nos intervalos depois do espaço da tela
				IF ((Hcount > Hactive) AND (Vcount < Vactive)) THEN
					VGA_R <= "0000";
					VGA_G <= "0000";
					VGA_B <= "0000";
					
				--escreve na tela
				ELSE					
					IF (data = '0') THEN
						VGA_R <= "0000";
						VGA_G <= "0000";
						VGA_B <= "0000";
					ELSE
						VGA_R <= "1111";
						VGA_G <= "1111";
						VGA_B <= "1111";
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
END Behavior_VGA;