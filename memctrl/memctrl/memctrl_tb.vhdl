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
use ieee.std_logic_textio.all;
use std.textio.all;
use work.memctrl_pkg.all;

entity memctrl_tb is
end memctrl_tb;

architecture behavioural of memctrl_tb is

	signal op : Operation;
	signal a  : std_logic;
	signal b  : std_logic;
	signal x  : std_logic;

begin

	-- Instantiate the unit under test
	uut: memctrl
		port map(
			op_in => op,
			a_in => a,
			b_in => b,
			x_out => x
		);

	-- Drive the unit under test. Read stimulus from stimulus.txt and write results to results.txt
	process
		variable inLine, outLine : line;
		variable inData          : std_logic_vector(2 downto 0);
		variable outData         : std_logic;
		file inFile              : text open read_mode is "stimulus.txt";
		file outFile             : text open write_mode is "results.txt";
	begin
		loop
			exit when endfile(inFile);
			readline(inFile, inLine);
			read(inLine, inData);
			if ( inData(2) = '1' ) then
				op <= OP_AND;
			else
				op <= OP_OR;
			end if;
			a <= inData(1);
			b <= inData(0);
			wait for 10 ns;
			outData := x;
			write(outLine, outData);
			writeline(outFile, outLine);
		end loop;
		wait;
		--assert false report "NONE. End of simulation." severity failure;
	end process;
end architecture;
