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
use work.hexutil.all;

entity memctrl_tb is
end memctrl_tb;

architecture behavioural of memctrl_tb is

	signal mcRst       : std_logic;
	signal mcClk       : std_logic;
	signal mcOp        : MCOpType;
	signal mcAddr      : std_logic_vector(21 downto 0);
	signal mcData_in   : std_logic_vector(15 downto 0);
	signal mcData_out  : std_logic_vector(15 downto 0);
	signal mcBusy      : std_logic;

	signal ramCmd      : std_logic_vector(2 downto 0);
	signal ramClk      : std_logic;
	signal ramRAS      : std_logic;
	signal ramCAS      : std_logic;
	signal ramWE       : std_logic;
	signal ramAddr     : std_logic_vector(11 downto 0);
	signal ramData_io  : std_logic_vector(15 downto 0);
	signal ramBank_out : std_logic_vector(1 downto 0);
	signal ramLDQM     : std_logic;
	signal ramUDQM     : std_logic;
	
begin

	-- Instantiate the unit under test
	uut: memctrl
		generic map(
			INIT_COUNT => "0" & x"004"
		)
		port map(
			mcRst_in    => mcRst,
			mcClk_in    => mcClk,
			mcOp_in     => mcOp,
			mcAddr_in   => mcAddr,
			mcData_in   => mcData_in,
			mcData_out  => mcData_out,
			mcBusy_out  => mcBusy,
			ramRAS_out  => ramRAS,
			ramCAS_out  => ramCAS,
			ramWE_out   => ramWE,
			ramAddr_out => ramAddr,
			ramData_io  => ramData_io,
			ramBank_out => ramBank_out,
			ramLDQM_out => ramLDQM,
			ramUDQM_out => ramUDQM
		);

	ramCmd <= ramRAS & ramCAS & ramWE;
	
	-- Drive the unit under test. Read stimulus from stimulus.txt and write results to results.txt
	process
		variable inLine, outLine : line;
		variable outData         : std_logic;
		file inFile              : text open read_mode is "stimulus.txt";
		file outFile             : text open write_mode is "results.txt";
		function to_op(c : character) return MCOpType is begin
			case c is
				when 'R' =>
					return MC_RD;
				when 'W' =>
					return MC_WR;
				when others =>
					return MC_NOP;
			end case;
		end function;
	begin
		mcClk <= '0';
		ramClk <= '0';
		mcRst <= '1';
		mcOp <= MC_NOP;
		mcAddr <= (others => 'X');
		mcData_in <= (others => 'X');
		ramData_io <= (others => 'X');		

		wait for 10 ns;
		ramClk <= '1';
		wait for 4 ns;
		mcClk <= '1';

		wait for 6 ns;
		ramClk <= '0';
		wait for 4 ns;
		mcRst <= '0';
		while ( not endfile(inFile) ) loop
			mcClk <= '0';
			wait for 6 ns;
			ramClk <= '1';
			wait for 4 ns;
			mcClk <= '1';
			readline(inFile, inLine);
			while ( inLine.all(1) = '#' ) loop
				readline(inFile, inLine);
			end loop;
			mcOp <= to_op(inLine.all(1));
			mcAddr <= to_2(inLine.all(3)) & to_4(inLine.all(4)) & to_4(inLine.all(5)) & to_4(inLine.all(6)) & to_4(inLine.all(7)) & to_4(inLine.all(8));
			mcData_in <= to_4(inLine.all(10)) & to_4(inLine.all(11)) & to_4(inLine.all(12)) & to_4(inLine.all(13));
			ramData_io <= to_4(inLine.all(15)) & to_4(inLine.all(16)) & to_4(inLine.all(17)) & to_4(inLine.all(18));
			wait for 6 ns;
			outData := mcBusy;
			ramClk <= '0';
			wait for 4 ns;
			write(outLine, outData);
			writeline(outFile, outLine);
		end loop;
		wait;
		--assert false report "NONE. End of simulation." severity failure;
	end process;
	process
	begin
		loop
			ramData_io <= (others => 'Z');
			wait until ramRAS = '1' and ramCAS = '0' and ramWE = '1' and mcClk = '1';
			wait until mcClk = '0';
			wait until mcClk = '1';
			wait until mcClk = '0';
			wait until mcClk = '1';
			wait for 6 ns;
			ramData_io <= x"CAFE";
			wait until mcClk = '0';
			wait until mcClk = '1';
			wait for 3 ns;
		end loop;
	end process;
end architecture;
