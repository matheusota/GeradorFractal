LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.fixed_pkg.all;

ENTITY mandelbrot IS
	PORT(
		x_const_in, y_const_in	:IN STD_LOGIC_VECTOR (35 DOWNTO 0);
		clk, rst	:IN STD_LOGIC;
		escape		:BUFFER std_logic;
		HEX1						:OUT STD_LOGIC_VECTOR(6 downto 0);
		done		:OUT STD_LOGIC
	);
END ENTITY mandelbrot;

ARCHITECTURE Behavior_mandelbrot of mandelbrot IS
	CONSTANT limit			:sfixed(3 downto 0) := X"4";
	SIGNAL x, y	:sfixed(3 downto -32);
	SIGNAL i : INTEGER;
	SIGNAL x_const, y_const : sfixed(3 downto -32);
BEGIN
	x_const <= to_sfixed(x_const_in, x_const);
	y_const <= to_sfixed(y_const_in, y_const);
	Process(clk,rst)
		variable x_sqr, y_sqr	:sfixed(3 downto -32);
	BEGIN
		IF (clk'EVENT and clk = '1') THEN
			done <= '0';
			IF (rst = '1') THEN
				x <= (others => '0');
				y <= (others => '0');
				escape <= '0';
				i <= 0;
			ELSE
				IF(i <= 1 AND escape = '0') THEN
					--calcula x^2 e y^2
					x_sqr := resize(x * x, x_sqr);
					y_sqr := resize(y * y, y_sqr);
					
					--x_n+1 = x_n^2 - y_n^2 + x_0
					--y_n+1 = 2*x_n*y_n + y_0
					x <= resize(x_sqr - y_sqr + x_const, x);
					y <= resize(((x * y) sla 1) + y_const, y);
					
					--se |z|^2 > 4 o ponto escapa
					IF (resize(x_sqr + y_sqr, limit) > limit) THEN
						HEX1(0) <= '1';
						escape <= '1';
					END IF;
					
					i <= i + 1;
				ELSE
					done <= '1';
				END IF;
			END IF;
		END IF;
	END PROCESS;
END Behavior_mandelbrot;