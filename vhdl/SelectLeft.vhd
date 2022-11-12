----------------------------------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Rachel Cazolla, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    SelectLeft - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

-- SelectLeft picks just the top bit from the given R, G, and B color channels.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity SelectLeft is
   port(
      R: in std_logic_vector(7 downto 0);
      G: in std_logic_vector(7 downto 0);
      B: in std_logic_vector(7 downto 0);
      RGB3: out std_logic_vector(2 downto 0)
   );
end SelectLeft;

architecture beh of SelectLeft is
begin

   RGB3 <= R(7) & G(7) & B(7);

end beh;

