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

entity TopLevel is
	port(
		-- Main 50MHz clock
		clk        : in    std_logic;

		-- Reset button (BTN0)
		reset      : in   std_logic;
	
		-- Host interface signals
		eppDataBus      : inout std_logic_vector(7 downto 0);
		eppAddrStrobe   : in    std_logic;
		eppDataStrobe   : in    std_logic;
		eppReadNotWrite : in    std_logic;
		eppAck          : out   std_logic;

		led        : out   std_logic_vector(1 downto 0)
	);
end TopLevel;

architecture Behavioural of TopLevel is
	component fifo_generator_v5_1  -- From CoreGen's .vho file
		port(
			clk   : in  std_logic;
			din   : in  std_logic_vector(7 downto 0);
			rd_en : in  std_logic;
			rst   : in  std_logic;
			wr_en : in  std_logic;
			dout  : out std_logic_vector(7 downto 0);
			empty : out std_logic;
			full  : out std_logic
		);
	end component;
	attribute box_type : string;
	attribute box_type of fifo_generator_v5_1 : component is "black_box";

	type State is (
		STATE_IDLE,

		STATE_ADDR_WRITE_EXEC,
		STATE_ADDR_WRITE_ACK,

		STATE_DATA_WRITE_EXEC,
		STATE_DATA_WRITE_ACK,

		STATE_DATA_READ_EXEC,
		STATE_DATA_READ_ACK
	);

	-- State and next-state
	signal iThisState, iNextState : State;

	-- Synchronised versions of asynchronous inputs
	signal iSyncAddrStrobe              : std_logic;
	signal iSyncDataStrobe              : std_logic;
	signal iSyncReadNotWrite            : std_logic;
	
	-- FIFO read/write enables, and data to be mux'd back to host
	signal iWriteEnable                 : std_logic;
	signal iReadEnable                  : std_logic;
	signal iDataOutput                  : std_logic_vector(7 downto 0);
	signal iFifoData                    : std_logic_vector(7 downto 0);

	-- Registers
	signal iThisRegAddr, iNextRegAddr   : std_logic_vector(1 downto 0);
	signal iThisAck, iNextAck           : std_logic;
	signal iThisR0, iNextR0             : std_logic_vector(7 downto 0);
	signal iThisR1, iNextR1             : std_logic_vector(7 downto 0);
	signal iThisR2, iNextR2             : std_logic_vector(7 downto 0);

begin

	fifo : fifo_generator_v5_1
		port map(
			clk             => clk,
			din             => eppDataBus,
			rd_en           => iReadEnable,
			rst             => reset,
			wr_en           => iWriteEnable,
			dout            => iFifoData,
			empty           => led(0),
			full            => led(1)
		);

	-- Drive the outputs
	eppAck <= iThisAck;

	-- EPP operation
	eppDataBus <=
		iDataOutput when ( eppReadNotWrite = '1' ) else
		"ZZZZZZZZ";

	with ( iThisRegAddr ) select
		iDataOutput <=
			iThisR0 when "00",
			iThisR1 when "01",
			iThisR2 when "10",
			iFifoData when others;

	-- Infer registers
	process(clk, reset)
	begin
		if ( reset = '1' ) then
			iThisState        <= STATE_IDLE;
			iThisRegAddr      <= (others => '0');
			iThisR0           <= (others => '0');
			iThisR1           <= (others => '0');
			iThisR2           <= (others => '0');
			iThisAck          <= '0';
			iSyncAddrStrobe   <= '1';
			iSyncDataStrobe   <= '1';
			iSyncReadNotWrite <= '1';
		elsif ( clk'event and clk = '1' ) then
			iThisState        <= iNextState;
			iThisRegAddr      <= iNextRegAddr;
			iThisR0           <= iNextR0;
			iThisR1           <= iNextR1;
			iThisR2           <= iNextR2;
			iThisAck          <= iNextAck;
			iSyncAddrStrobe   <= eppAddrStrobe;
			iSyncDataStrobe   <= eppDataStrobe;
			iSyncReadNotWrite <= eppReadNotWrite;
		end if;
	end process;

	-- Next state logic
	process(
		eppDataBus, iThisState, iThisRegAddr,
		iSyncAddrStrobe, iSyncDataStrobe, iSyncReadNotWrite,
		iThisR0, iThisR1, iThisR2)
	begin
		iNextAck        <= '0';
		iNextState      <= STATE_IDLE;
		iNextRegAddr    <= iThisRegAddr;
		iNextR0         <= iThisR0;
		iNextR1         <= iThisR1;
		iNextR2         <= iThisR2;
		iWriteEnable    <= '0';  -- No write to FIFO
		iReadEnable     <= '0';  -- No read from FIFO
		case iThisState is
			when STATE_IDLE =>
				if ( iSyncAddrStrobe = '0' ) then
					-- Address can only be written, not read
					if ( iSyncReadNotWrite = '0' ) then
						iNextState <= STATE_ADDR_WRITE_EXEC;
					end if;
				elsif ( iSyncDataStrobe = '0' ) then
					-- Register read or write
					if ( iSyncReadNotWrite = '0' ) then
						iNextState <= STATE_DATA_WRITE_EXEC;
					else
						iNextState <= STATE_DATA_READ_EXEC;
					end if;
				end if;

			-- Write address register
			when STATE_ADDR_WRITE_EXEC =>
				iNextRegAddr <= eppDataBus(1 downto 0);
				iNextState   <= STATE_ADDR_WRITE_ACK;
				iNextAck     <= '0';
			when STATE_ADDR_WRITE_ACK =>
				if ( iSyncAddrStrobe = '0' ) then
					iNextState <= STATE_ADDR_WRITE_ACK;
					iNextAck   <= '1';
				else
					iNextState <= STATE_IDLE;
					iNextAck   <= '0';
				end if;

			-- Write data register
			when STATE_DATA_WRITE_EXEC =>
				case iThisRegAddr is
					when "00" =>
						iNextR0 <= eppDataBus;
					when "01" =>
						iNextR1 <= eppDataBus;
					when "10" =>
						iNextR2 <= eppDataBus;
					when others =>
						iWriteEnable <= '1';  -- Write to FIFO
				end case;
				iNextState <= STATE_DATA_WRITE_ACK;
				iNextAck   <= '1';
			when STATE_DATA_WRITE_ACK =>
				if ( iSyncDataStrobe = '0' ) then
					iNextState <= STATE_DATA_WRITE_ACK;
					iNextAck   <= '1';
				else
					iNextState <= STATE_IDLE;
					iNextAck   <= '0';
				end if;

			-- Read data register
			when STATE_DATA_READ_EXEC =>
				iNextAck    <= '1';
				iNextState  <= STATE_DATA_READ_ACK;
				if ( iThisRegAddr = "11" ) then
					iReadEnable <= '1';
				end if;
			when STATE_DATA_READ_ACK =>
				if ( iSyncDataStrobe = '0' ) then
					iNextState <= STATE_DATA_READ_ACK;
					iNextAck   <= '1';
				else
					iNextState <= STATE_IDLE;
					iNextAck   <= '0';
				end if;

			-- Some unknown state
			when others =>
				iNextState <= STATE_IDLE;
		end case;
	end process;
end Behavioural;
