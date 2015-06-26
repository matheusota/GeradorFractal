library ieee;
use ieee.std_logic_1164.all;

entity edge is
port (
	q : in std_logic;
	e : out std_logic;
	clk : in std_logic
	);
end entity;

architecture rtl of edge is
	signal old: std_logic;
begin
	process (clk)
	begin
		if rising_edge(clk) then
			old <= q;
			if (old = '1' and q = '0') then
				e <= '1';
			else
				e <= '0';
			end if;
		end if;
	end process;
end rtl;
	