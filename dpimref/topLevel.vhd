--
-- Copyright (C) 2010 Chris McClelland
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
		eppDB      : inout std_logic_vector(7 downto 0);
		eppAstb    : in    std_logic;
		eppDstb    : in    std_logic;
		usbFlag    : in    std_logic;  -- R/!W
		eppWait    : out   std_logic;  -- Ack/!Wait

		-- Switches & LEDs
		sw         : in    std_logic_vector(7 downto 0);
		led        : out   std_logic_vector(7 downto 0)
	);
end TopLevel;

architecture Behavioural of TopLevel is
begin
	-- Interface with host over USB EPP-emulation
	--
	hostInterface : entity work.HostInterface
		port map(
			clk             => clk,
			reset           => reset,
			dataBus         => eppDB,
			addrStrobe      => eppAstb,
			dataStrobe      => eppDstb,
			readNotWrite    => usbFlag,
			ack             => eppWait,
			r3in            => sw,
			r3out           => led
		);
end Behavioural;
