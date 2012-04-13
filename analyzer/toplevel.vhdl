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

entity toplevel is
	port(
		ifclk_in     : in std_logic;

		-- Data & control from the FX2
		fifoData_io  : inout std_logic_vector(7 downto 0);
		gotData_in   : in std_logic;                     -- FLAGC=EF (active-low), so '1' when there's data
		gotRoom_in   : in std_logic;                     -- FLAGB=FF (active-low), so '1' when there's room

		-- Control to the FX2
		sloe_out     : out std_logic;                    -- PA2
		slrd_out     : out std_logic;
		slwr_out     : out std_logic;
		fifoAddr_out : out std_logic_vector(1 downto 0); -- PA4 & PA5
		pktEnd_out   : out std_logic;                    -- PA6

		-- Onboard peripherals
		sseg_out     : out std_logic_vector(7 downto 0);
		anode_out    : out std_logic_vector(3 downto 0);
		led_out      : out std_logic_vector(7 downto 0);

		async_in     : in  std_logic
	);
end toplevel;

architecture behavioural of toplevel is
	type StateType is (
		STATE_IDLE,
		STATE_GET_COUNT0,
		STATE_GET_COUNT1,
		STATE_GET_COUNT2,
		STATE_GET_COUNT3,
		STATE_BEGIN_WRITE,
		STATE_WRITE,
		STATE_END_WRITE_ALIGNED,
		STATE_END_WRITE_NONALIGNED,
		STATE_READ
	);
	signal state, state_next         : StateType := STATE_IDLE;
	signal count, count_next         : unsigned(31 downto 0);  -- Read/Write count
	signal addr, addr_next           : std_logic_vector(1 downto 0);
	signal isWrite, isWrite_next     : std_logic;
	signal isAligned, isAligned_next : std_logic;
	signal checksum, checksum_next   : std_logic_vector(15 downto 0) := x"0000";
	signal r0, r1, r0_next, r1_next  : std_logic_vector(7 downto 0) := x"00";
	signal r2, r3, r2_next, r3_next  : std_logic_vector(7 downto 0) := x"00";
	signal fifoOp                    : std_logic_vector(2 downto 0);
	signal fifoDataIn, fifoDataOut   : std_logic_vector(7 downto 0);
	signal fifoReadEnable            : std_logic;
	signal fifoWriteEnable           : std_logic;
	signal fifoEmpty, fifoFull       : std_logic;
	signal triggerProducer, alarm    : std_logic;
	constant FIFO_READ               : std_logic_vector(2 downto 0) := "100";  -- assert slrd_out & sloe_out
	constant FIFO_WRITE              : std_logic_vector(2 downto 0) := "011";  -- assert slwr_out
	constant FIFO_NOP                : std_logic_vector(2 downto 0) := "111";  -- assert nothing
	constant OUT_FIFO                : std_logic_vector(1 downto 0) := "10"; -- EP6OUT
	constant IN_FIFO                 : std_logic_vector(1 downto 0) := "11"; -- EP8IN
begin
	process(ifclk_in)
	begin
		if ( rising_edge(ifclk_in) ) then
			state     <= state_next;
			count     <= count_next;
			addr      <= addr_next;
			isWrite   <= isWrite_next;
			isAligned <= isAligned_next;
			checksum  <= checksum_next;
			r0        <= r0_next;
			r1        <= r1_next;
			r2        <= r2_next;
			r3        <= r3_next;
		end if;
	end process;
	
	-- Next state logic
	process(
		state, fifoData_io, gotData_in, gotRoom_in, count, isAligned, isWrite, addr,
		r0, r1, r2, r3, checksum, fifoEmpty, fifoDataOut)
	begin
		state_next     <= state;
		count_next     <= count;
		addr_next      <= addr;
		isWrite_next   <= isWrite;
		isAligned_next <= isAligned;  -- does this FIFO write end on a block (512-byte) boundary?
		checksum_next  <= checksum;
		r0_next        <= r0;
		r1_next        <= r1;
		r2_next        <= r2;
		r3_next        <= r3;
		fifoData_io    <= (others => 'Z');  -- Tristated unless explicitly driven
		fifoOp         <= FIFO_READ;        -- read the FX2LP FIFO by default
		pktEnd_out     <= '1';              -- inactive: FPGA does not commit a short packet.

		fifoReadEnable <= '0';
		triggerProducer <= '0';
		
		case state is

			when STATE_IDLE =>
				fifoAddr_out <= OUT_FIFO;  -- Reading from FX2LP
				if ( gotData_in = '1' ) then
					-- The read/write flag and a seven-bit register address will be available on the
					-- next clock edge.
					addr_next    <= fifoData_io(1 downto 0);
					isWrite_next <= fifoData_io(7);
					state_next   <= STATE_GET_COUNT0;
				end if;

			when STATE_GET_COUNT0 =>
				fifoAddr_out <= OUT_FIFO;  -- Reading from FX2LP
				if ( gotData_in = '1' ) then
					-- The count high word high byte will be available on the next clock edge.
					count_next(31 downto 24) <= unsigned(fifoData_io);
					state_next <= STATE_GET_COUNT1;
				end if;

			when STATE_GET_COUNT1 =>
				fifoAddr_out <= OUT_FIFO;  -- Reading from FX2LP
				if ( gotData_in = '1' ) then
					-- The count high word low byte will be available on the next clock edge.
					count_next(23 downto 16) <= unsigned(fifoData_io);
					state_next <= STATE_GET_COUNT2;
				end if;

			when STATE_GET_COUNT2 =>
				fifoAddr_out <= OUT_FIFO;  -- Reading from FX2LP
				if ( gotData_in = '1' ) then
					-- The count low word high byte will be available on the next clock edge.
					count_next(15 downto 8) <= unsigned(fifoData_io);
					state_next <= STATE_GET_COUNT3;
				end if;

			when STATE_GET_COUNT3 =>
				fifoAddr_out <= OUT_FIFO;  -- Reading from FX2LP
				if ( gotData_in = '1' ) then
					-- The count low word low byte will be available on the next clock edge.
					count_next(7 downto 0) <= unsigned(fifoData_io);
					if ( isWrite = '1' ) then
						state_next <= STATE_BEGIN_WRITE;
					else
						state_next <= STATE_READ;
					end if;
				end if;

			when STATE_BEGIN_WRITE =>
				fifoAddr_out   <= IN_FIFO;   -- Writing to FX2LP
				fifoOp         <= FIFO_NOP;
				isAligned_next <= not(count(0) or count(1) or count(2) or count(3) or count(4) or count(5) or count(6) or count(7) or count(8));
				triggerProducer <= '1';
				state_next     <= STATE_WRITE;

			when STATE_WRITE =>
				fifoAddr_out <= IN_FIFO;   -- Writing to FX2LP
				if ( gotRoom_in = '1' and (addr /= "00" or fifoEmpty = '0') ) then
					fifoOp <= FIFO_WRITE;
					case addr is
						when "00" =>
							fifoData_io <= fifoDataOut;
							fifoReadEnable <= '1';
						when "01" =>
							fifoData_io <= r1;
							count_next  <= count - 1;
						when "10" =>
							fifoData_io <= r2;
							count_next  <= count - 1;
						when others =>
							fifoData_io <= r3;
							count_next  <= count - 1;
					end case;
					count_next  <= count - 1;
					if ( count = 1 ) then
						if ( isAligned = '1' ) then
							state_next <= STATE_END_WRITE_ALIGNED;  -- don't assert pktEnd
						else
							state_next <= STATE_END_WRITE_NONALIGNED;  -- assert pktEnd to commit small packet
						end if;
					end if;
				else
					fifoOp <= FIFO_NOP;
				end if;

			when STATE_END_WRITE_ALIGNED =>
				fifoAddr_out <= IN_FIFO;   -- Writing to FX2LP
				fifoOp       <= FIFO_NOP;
				state_next   <= STATE_IDLE;

			when STATE_END_WRITE_NONALIGNED =>
				fifoAddr_out <= IN_FIFO;   -- Writing to FX2LP
				fifoOp       <= FIFO_NOP;
				pktEnd_out   <= '0';  	   -- Active: FPGA commits the packet.
				state_next   <= STATE_IDLE;

			when STATE_READ =>
				fifoAddr_out <= OUT_FIFO;  -- Reading from FX2LP
				if ( gotData_in = '1' ) then
					-- A data byte will be available on the next clock edge
					case addr is
						when "00" =>
							r0_next <= fifoData_io;
							checksum_next <= std_logic_vector(
								unsigned(checksum) + unsigned(fifoData_io));  -- Update R0 checksum
						when "01" =>
							r1_next <= fifoData_io;  -- Writing a '1' to bit 0 of R1 clears R0 cksum
							if ( fifoData_io(0) = '1' ) then
								checksum_next <= (others => '0');
							end if;
						when "10" =>
							r2_next <= fifoData_io;
						when others =>
							r3_next <= fifoData_io;
					end case;
					count_next  <= count - 1;
					if ( count = 1 ) then
						state_next <= STATE_IDLE;
					end if;
				end if;
		end case;
	end process;

	-- Breakout fifoOp
	sloe_out <= fifoOp(0);
	slrd_out <= fifoOp(1);
	slwr_out <= fifoOp(2);
	
	-- LEDs and 7-seg display
	led_out     <= r0;
	sseg_out(7) <= alarm;  -- Decimal point off
	sevenseg : entity work.sevenseg
		port map(
			clk_in     => ifclk_in,
			data_in    => checksum,
			segs_out   => sseg_out(6 downto 0),
			anodes_out => anode_out
		);

	-- Producer of FIFO data
	producer : entity work.producer
		port map (
			clk_in     => ifclk_in,
			data_out   => fifoDataIn,
			write_out  => fifoWriteEnable,
			full_in    => fifoFull,
			trigger_in => triggerProducer,
			count_in   => count,
			alarm_out  => alarm,
			ch_in      => async_in
		);
	
	-- FIFO generator
	fifogen : entity work.fifogen
		port map(
			clk   => ifclk_in,

			-- Putting stuff into the FIFO:
			din   => fifoDataIn,
			wr_en => fifoWriteEnable,
			full  => fifoFull,

			-- Taking stuff out of the FIFO:
			rd_en => fifoReadEnable,
			dout  => fifoDataOut,
			empty => fifoEmpty
		);
end behavioural;
