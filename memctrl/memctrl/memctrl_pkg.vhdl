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

package memctrl_pkg is
	type MCOpType is (
		MC_NOP,
		MC_RD,
		MC_WR
	);
	component memctrl is
		generic (
			INIT_COUNT : unsigned(12 downto 0)
		);
		port(
			-- Client interface
			mcRst_in    : in std_logic;
			mcClk_in    : in std_logic;
			mcOp_in     : in MCOpType;
			mcAddr_in   : in std_logic_vector(21 downto 0);
			mcData_in   : in std_logic_vector(15 downto 0);
			mcData_out  : out std_logic_vector(15 downto 0);
			mcBusy_out  : out std_logic;

			-- SDRAM interface
			ramRAS_out  : out std_logic;
			ramCAS_out  : out std_logic;
			ramWE_out   : out std_logic;
			ramAddr_out : out std_logic_vector(11 downto 0);
			ramData_io  : inout std_logic_vector(15 downto 0);
			ramBank_out : out std_logic_vector(1 downto 0);
			ramLDQM_out : out std_logic;
			ramUDQM_out : out std_logic
		);
	end component;
end package;
