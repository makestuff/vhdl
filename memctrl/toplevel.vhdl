--
-- Copyright (C) 2011 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.memctrl_pkg.all;

entity toplevel is
	port(
		op_in : in std_logic;
		a_in  : in std_logic;
		b_in  : in std_logic;
		x_out : out std_logic
	);
end entity;
 
architecture behavioural of toplevel is
	signal op : Operation;
begin
	u1: memctrl
		port map(
			op_in => op,
			a_in => a_in,
			b_in => b_in,
			x_out => x_out
		);
	op <=
		OP_AND when op_in = '1' else
		OP_OR;
end architecture;
