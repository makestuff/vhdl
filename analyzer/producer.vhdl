--
-- Copyright (C) 2009-2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity producer is
	port(
		clk_in     : in  std_logic;
		data_out   : out std_logic_vector(7 downto 0);
		write_out  : out std_logic;
		full_in    : in  std_logic;
		trigger_in : in  std_logic;
		count_in   : in  unsigned(31 downto 0);
		alarm_out  : out std_logic;
		ch_in      : in  std_logic
		--ch_in      : in  std_logic_vector(1 downto 0)
	);
end producer;

architecture behavioural of producer is
	type StateType is (
		STATE_IDLE,
		STATE_GET0,
		STATE_GET1,
		STATE_GET2,
		STATE_GET3
	);
	signal state, state_next       : StateType := STATE_IDLE;
	signal count, count_next       : unsigned(31 downto 0);  -- Write count
	signal alarm, alarm_next       : std_logic := '0';
	signal chanBits, chanBits_next : std_logic_vector(5 downto 0) := "000000";
	signal ch_sync1                : std_logic;
	signal ch_sync2                : std_logic;
	signal ch_sync3                : std_logic;
	--signal ch_sync1                : std_logic_vector(1 downto 0) := "00";
	--signal ch_sync2                : std_logic_vector(1 downto 0) := "00";
	--signal ch_sync3                : std_logic_vector(1 downto 0) := "00";
	--signal ch, ch_next             : std_logic_vector(1 downto 0) := "00";
begin
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			state    <= state_next;
			count    <= count_next;
			alarm    <= alarm_next;
			chanBits <= chanBits_next;
			ch_sync1  <= ch_in;
			ch_sync2  <= ch_sync1;
			ch_sync3  <= ch_sync2;
			--ch        <= ch_next;
		end if;
	end process;

	--ch_next <=
	--	ch_sync2 when ch_sync1 = ch_sync2 and ch_sync2 = ch_sync3 else
	--	ch;
	
	alarm_next <=
		'1' when full_in = '1'
		else alarm;
	alarm_out <= alarm;
	
	process(state, count, chanBits, ch_sync2, ch_sync3, count_in, trigger_in)
	begin
		state_next <= state;
		count_next <= count;
		write_out <= '0';
		chanBits_next <= chanBits;
		data_out <= (others => '0');
		case state is
			when STATE_GET0 =>
				chanBits_next(1 downto 0) <= ch_sync2 & ch_sync3;
				state_next <= STATE_GET1;

			when STATE_GET1 =>
				chanBits_next(3 downto 2) <= ch_sync2 & ch_sync3;
				state_next <= STATE_GET2;

			when STATE_GET2 =>
				chanBits_next(5 downto 4) <= ch_sync2 & ch_sync3;
				state_next <= STATE_GET3;

			when STATE_GET3 =>
				--data_out <= std_logic_vector(count(7 downto 0));
				data_out <= ch_sync2 & ch_sync3 & chanBits;
				write_out <= '1';
				count_next <= count - 1;
				if ( count = 1 ) then
					state_next <= STATE_IDLE;
				else
					state_next <= STATE_GET0;
				end if;

			-- STATE_IDLE and others
			when others =>
				if ( trigger_in = '1' ) then
					state_next <= STATE_GET0;
					count_next <= count_in;
				end if;
		end case;
	end process;
end behavioural;
