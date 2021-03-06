LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.fixed_pkg.all;

ENTITY control IS
	PORT(
		clk, rst						:IN STD_LOGIC;
		zoom_mid, zoom_l, zoom_r		:IN STD_LOGIC;
		done					:IN STD_LOGIC;
		x_const, y_const			:OUT STD_LOGIC_VECTOR(35 downto 0);
		x_addr, y_addr, write_addr	:OUT STD_LOGIC_VECTOR(9 downto 0);
		WE_const				:buffer STD_LOGIC;
		reset_mandelbrot		:OUT STD_LOGIC
	);
END ENTITY control;

ARCHITECTURE Behavior_control OF control IS
	TYPE state_type IS (Start, Write_Memory, Write_Pixel, Write_Pixel_Wait, Final);
	SIGNAL cur_state		:state_type;
	SIGNAL x_counter		:UNSIGNED(9 downto 0);
	SIGNAL y_counter		:UNSIGNED(9 downto 0);
	SIGNAL write_counter		:UNSIGNED(9 downto 0);
	SIGNAL x_com_min, x_com_max, y_com_min, y_com_max :sfixed(3 downto -32);
	SIGNAL h_pixel, w_pixel, h_npixel, w_npixel, x_int_const, y_int_const	:sfixed(3 downto -32);
	SIGNAL iteration_counter	:UNSIGNED(15 downto 0);
	CONSTANT x_size			:sfixed(10 downto 0) := "01010000000"; --640
	CONSTANT y_size			:sfixed(10 downto 0) := "00111100000"; --480
	signal zoom_mid_edge, zoom_l_edge, zoom_r_edge : std_logic;

component edge is
port (
	q : in std_logic;
	e : out std_logic;
	clk : in std_logic
	);
end component;
	
	
BEGIN

	detector1 : edge port map (zoom_mid, zoom_mid_edge, clk);
	detector2 : edge port map (zoom_l, zoom_l_edge, clk);
	detector3 : edge port map (zoom_r, zoom_r_edge, clk);

	x_const <= STD_LOGIC_VECTOR(x_int_const);
	y_const <= STD_LOGIC_VECTOR(y_int_const);
	x_addr <= STD_LOGIC_VECTOR(x_counter);
	y_addr <= STD_LOGIC_VECTOR(y_counter);
	write_addr <= STD_LOGIC_VECTOR(write_counter);
	PROCESS(clk, rst)
	variable x_span, y_span: sfixed (4 downto -32);
	BEGIN
		IF (clk'EVENT and clk = '1') THEN
			IF (rst = '1') THEN
				x_com_min <= to_sfixed(-2, x_com_min);
				x_com_max <= to_sfixed(1, x_com_max);
				
				y_com_min <= to_sfixed(-1, y_com_min);
				y_com_max <= to_sfixed(1, y_com_max);
				
				x_int_const <= (others => '0');--to_sfixed(-2, x_int_const);
				y_int_const <= (others => '0');--to_sfixed(-1, y_int_const);
				
				w_pixel <= to_sfixed(0.0046875, w_pixel);--3/640
				h_pixel <= to_sfixed(0.0041667, h_pixel);--2/480

				WE_const <= '1';
				write_counter <= (others => '0');
				
				cur_state <= Start;
			ELSE
				reset_mandelbrot <= '1';
				WE_const <= '0';
				CASE cur_state IS
					--
					WHEN Start =>
						x_int_const <= x_com_min;
						y_int_const <= y_com_min;
						write_counter <= (others => '0');
						WE_const <= '1';
						cur_state <= Write_Memory;
					-- carrega os pixels nas constMem como se fossem pontos do plano complexo
					WHEN Write_Memory =>
						x_int_const <= resize(x_int_const + w_pixel, x_int_const);
						y_int_const <= resize(y_int_const + h_pixel, y_int_const);
						write_counter <= write_counter + 1;
						
						IF (write_counter = 639) THEN
							x_counter <= (others => '0');
							y_counter <= (others => '0');
							cur_state <= Write_Pixel_Wait;
						--else
							--WE_const <= '1';
						END IF;
						WE_const <= '1';
					-- manda os pixels para iterar na funcao de mandelbrot
					WHEN Write_Pixel =>
						x_counter <= x_counter + 1;
						
						--completou a linha
						IF (x_counter = 639) THEN
							y_counter <= y_counter + 1;
							x_counter <= (others => '0');
						END IF;
						
						cur_state <= Write_Pixel_Wait;
					-- espera ele iterar na funcao
					WHEN Write_Pixel_Wait =>
						--terminou de salvar todos os pontos
						
						--continua salvado os pontos
						IF done = '1' THEN
							IF (y_counter = 479 and x_counter = 639) THEN
								cur_state <= Final;
							else
								cur_state <= Write_Pixel;
							end if;
						--end if;
						ELSE
							reset_mandelbrot <= '0';
						END IF;
					--espera comando do usuario(zoom)
					WHEN Final =>
					
						IF (zoom_mid_edge = '1' OR zoom_r_edge = '1' OR zoom_l_edge = '1') THEN
							x_span := x_com_max - x_com_min;
							y_span := y_com_max - y_com_min;
							
							y_com_min <= resize(y_com_min + y_span / 4, y_com_min);
							y_com_max <= resize(y_com_max - y_span / 4, y_com_max);
							
							w_pixel <= resize(w_pixel / 2, w_pixel);
							h_pixel <= resize(h_pixel / 2, h_pixel);
							
							--zoom no centro da tela
							IF (zoom_mid_edge = '1') THEN
								x_com_min <= resize(x_com_min + x_span / 4, x_com_min);
								x_com_max <= resize(x_com_max - x_span / 4, x_com_max);
--							--zoom no lado direito da tela
							ELSIF (zoom_r_edge = '1') THEN
								x_com_min <= resize(x_com_min + x_span/2, x_com_min);
--							--zoom no lado esquerdo da tela
							ELSIF (zoom_l_edge = '1') THEN
								x_com_max <= resize(x_com_max - x_span/2, x_com_min);				
							END IF;
--							y_counter <= (others => '0');
--							x_counter <= (others => '0');
							cur_state <= Start;
						END IF;
				END CASE;
			END IF;
		END IF;
	END PROCESS;
END Behavior_control;