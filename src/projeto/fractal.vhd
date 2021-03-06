LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY work;
USE work.fixed_pkg.all;

ENTITY fractal IS
	PORT(
		CLOCK_50 : IN STD_LOGIC;
		KEY : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_HS : OUT STD_LOGIC;
		VGA_VS : OUT STD_LOGIC;
		SRAM_ADDR : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
		SRAM_DQ : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		SRAM_WE_N : OUT STD_LOGIC;
		SRAM_UB_N, SRAM_LB_N : OUT STD_LOGIC;
		HEX0	: OUT STD_LOGIC_VECTOR(6 downto 0);
		HEX1	: OUT STD_LOGIC_VECTOR(6 downto 0)
	);
END ENTITY fractal;

ARCHITECTURE Behavior_fractal of fractal IS
	signal clock_24 : STD_LOGIC;
	signal done : STD_LOGIC;
	signal write_addr : STD_LOGIC_VECTOR(9 downto 0);
	signal WE_const : STD_LOGIC;
	signal pixel_x : STD_LOGIC_VECTOR (35 DOWNTO 0);
	signal pixel_y : STD_LOGIC_VECTOR (35 DOWNTO 0);
	signal result : STD_LOGIC;
	signal zoom_mid : STD_LOGIC;
	signal zoom_l : STD_LOGIC;
	signal zoom_r : STD_LOGIC;
	signal rst : STD_LOGIC;
	signal R_out : STD_LOGIC;
	signal R_start : STD_LOGIC;
	signal x_const : STD_LOGIC_VECTOR(35 downto 0);
	signal y_const : STD_LOGIC_VECTOR(35 downto 0);
	signal x_addr : STD_LOGIC_VECTOR(9 downto 0);
	signal y_addr : STD_LOGIC_VECTOR(9 downto 0);
	signal reset_mandelbrot : STD_LOGIC;
	
	COMPONENT pll IS
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC
	);
	END COMPONENT;
	
	COMPONENT constMem IS
	PORT
	(
		clock		: IN STD_LOGIC;
		data		: IN STD_LOGIC_VECTOR (35 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wraddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wren		: IN STD_LOGIC;
		q		: OUT STD_LOGIC_VECTOR (35 DOWNTO 0)
	);
	END COMPONENT;
	
	COMPONENT control IS
	PORT(
		clk, rst						:IN STD_LOGIC;
		zoom_mid, zoom_l, zoom_r		:IN STD_LOGIC;
		done					:IN STD_LOGIC;
		x_const, y_const			:OUT STD_LOGIC_VECTOR(35 downto 0);
		x_addr, y_addr, write_addr	:OUT STD_LOGIC_VECTOR(9 downto 0);
		WE_const				:OUT STD_LOGIC;
		reset_mandelbrot		:OUT STD_LOGIC
	);
	END COMPONENT;
	
	COMPONENT mandelbrot IS
	PORT(
		x_const_in, y_const_in	:IN STD_LOGIC_VECTOR (35 DOWNTO 0);
		clk, rst	:IN STD_LOGIC;
		escape		:BUFFER std_logic;
		HEX1						:OUT STD_LOGIC_VECTOR(6 downto 0);
		done		:OUT STD_LOGIC
	);
	END COMPONENT;
	
	COMPONENT memory_control IS
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
	END COMPONENT;
BEGIN
	--atribui sinal dos zooms
	zoom_mid <= NOT KEY(1);
	zoom_l <= NOT KEY(2);
	zoom_r <= NOT KEY(0);
	
	--atribui sinal do reset_mandelbrot
	rst <= NOT KEY(3);
	
	--divide clock
	pll0: pll port map(CLOCK_50, clock_24);
	--processa cada pixel da tela como um ponto no plano complexo(z = x_cont + iy_const). O endereco � a posicao do pixel
	ctrl: control port map(clock_24, rst, zoom_mid, zoom_l, zoom_r, done, x_const, y_const, x_addr, y_addr, write_addr, WE_const, reset_mandelbrot);
	
	--salva os pontos calculados na memoria
	memX: constMem port map(clock_24, x_const, x_addr, write_addr, WE_const, pixel_x);
	memY: constMem port map(clock_24, y_const, y_addr, write_addr, WE_const, pixel_y);
	
	--verifica se o ponto z vai para infinito na itera��o de conjunto de mandelbrot. Retorna 1 se vai e 0 caso contr�rio
	math: mandelbrot port map(pixel_x, pixel_y, clock_24, reset_mandelbrot, result, HEX1, done);
	
	--plota os pontos calculados na tela
	memCtrl: memory_control port map(clock_24, rst, done, result, SRAM_DQ, SRAM_ADDR, SRAM_WE_N, SRAM_LB_N, SRAM_UB_N, VGA_R, VGA_G, VGA_B, HEX0, VGA_HS, VGA_VS);
	
END Behavior_fractal;