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

entity memctrl is
	generic (
		-- These real-hardware defaults are overridden by the testbench
		INIT_COUNT : unsigned(12 downto 0) := "1" & x"2C0"  -- 100uS @ 48MHz
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
end entity;

architecture behavioural of memctrl is
	type StateType is (
		STATE_RESET,
		STATE_INIT,
		STATE_READ0,
		STATE_READ1,
		STATE_READ2,
		STATE_IDLE
	);
	signal cmd       : std_logic_vector(2 downto 0);
	constant CMD_NOP : std_logic_vector(2 downto 0) := "111";
	constant CMD_ACT : std_logic_vector(2 downto 0) := "011";
	constant CMD_RD  : std_logic_vector(2 downto 0) := "101";
	constant CMD_WR  : std_logic_vector(2 downto 0) := "100";
	constant CMD_PRE : std_logic_vector(2 downto 0) := "010";
	constant CMD_LMR : std_logic_vector(2 downto 0) := "000";
	signal state          : StateType;
	signal state_next     : StateType;
	signal initCount      : unsigned(12 downto 0);
	signal initCount_next : unsigned(12 downto 0);
	signal colAddr        : std_logic_vector(7 downto 0);
	signal colAddr_next   : std_logic_vector(7 downto 0);
begin

	ramRAS_out <= cmd(2);
	ramCAS_out <= cmd(1);
	ramWE_out  <= cmd(0);
	
	-- Infer registers
	process(mcRst_in, mcClk_in)
	begin
		if ( mcRst_in = '1' ) then
			state <= STATE_RESET;
			initCount <= INIT_COUNT;
			colAddr <= (others => '0');
		elsif ( mcClk_in'event and mcClk_in = '1' ) then
			state <= state_next;
			initCount <= initCount_next;
			colAddr <= colAddr_next;
		end if;
	end process;

	-- Next state logic
	process(state, initCount, colAddr, mcOp_in, mcAddr_in)
	begin
		state_next <= state;
		initCount_next <= initCount - 1;
		colAddr_next <= colAddr;
		mcBusy_out <= '1';
		ramBank_out <= (others => 'Z');
		ramAddr_out <= (others => 'Z');
		cmd <= CMD_NOP;
		case state is
			when STATE_RESET =>
				state_next <= STATE_INIT;
				initCount_next <= INIT_COUNT;
			when STATE_INIT =>
				if ( initCount = "0" & x"000" ) then
					state_next <= STATE_IDLE;
				end if;
			when STATE_IDLE =>
				mcBusy_out <= '0';
				if ( mcOp_in = MC_RD ) then
					state_next <= STATE_READ0;
					colAddr_next <= mcAddr_in(7 downto 0);  -- Save the column address
					cmd <= CMD_ACT;
					ramBank_out <= mcAddr_in(21 downto 20);
					ramAddr_out <= mcAddr_in(19 downto 8);
				end if;
			when STATE_READ0 =>
				state_next <= STATE_READ1;
				cmd <= CMD_RD;
				ramAddr_out <= "0000" & colAddr;
			when STATE_READ1 =>
				cmd <= CMD_PRE;
				state_next <= STATE_READ2;
			when STATE_READ2 =>
				state_next <= STATE_IDLE;
		end case;
	end process;
	ramLDQM_out <= '1';
	ramUDQM_out <= '1';
	mcData_out <= ramData_io and mcData_in;
end architecture;
