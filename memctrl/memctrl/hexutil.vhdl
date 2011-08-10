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

package hexutil is
	function to_1(c : character) return std_logic;
	function to_2(c : character) return std_logic_vector;
	function to_3(c : character) return std_logic_vector;
	function to_4(c : character) return std_logic_vector;
end package;

package body hexutil is
	-- Return the bits of the supplied hex nibble
	function to_4(c : character) return std_logic_vector is
		variable nibble : std_logic_vector(3 downto 0);
	begin
		case c is
			when '0' =>
				nibble := "0000";
			when '1' =>
				nibble := "0001";
			when '2' =>
				nibble := "0010";
			when '3' =>
				nibble := "0011";
			when '4' =>
				nibble := "0100";
			when '5' =>
				nibble := "0101";
			when '6' =>
				nibble := "0110";
			when '7' =>
				nibble := "0111";
			when '8' =>
				nibble := "1000";
			when '9' =>
				nibble := "1001";
			when 'a' =>
				nibble := "1010";
			when 'A' =>
				nibble := "1010";
			when 'b' =>
				nibble := "1011";
			when 'B' =>
				nibble := "1011";
			when 'c' =>
				nibble := "1100";
			when 'C' =>
				nibble := "1100";
			when 'd' =>
				nibble := "1101";
			when 'D' =>
				nibble := "1101";
			when 'e' =>
				nibble := "1110";
			when 'E' =>
				nibble := "1110";
			when 'f' =>
				nibble := "1111";
			when 'F' =>
				nibble := "1111";
			when 'X' =>
				nibble := "XXXX";
			when 'x' =>
				nibble := "XXXX";
			when 'Z' =>
				nibble := "ZZZZ";
			when 'z' =>
				nibble := "ZZZZ";
			when others =>
				nibble := "UUUU";
		end case;
		return nibble;
	end function;

	-- Return the least-significant bit of the supplied hex nibble
	function to_1(c : character) return std_logic is
		variable nibble : std_logic_vector(3 downto 0);
	begin
		nibble := to_4(c);
		return nibble(0);
	end function;

	-- Return two least-significant bits of the supplied hex nibble
	function to_2(c : character) return std_logic_vector is
		variable nibble : std_logic_vector(3 downto 0);
	begin
		nibble := to_4(c);
		return nibble(1 downto 0);
	end function;

	-- Return three least-significant bits of the supplied hex nibble
	function to_3(c : character) return std_logic_vector is
		variable nibble : std_logic_vector(3 downto 0);
	begin
		nibble := to_4(c);
		return nibble(2 downto 0);
	end function;
end package body;
