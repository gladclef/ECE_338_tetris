----------------------------------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Racel Cazzola, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    ColorDecoder - Behavioral 
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

-- ColorDecoder translates from 3 bit to 24 bit color space

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity ColorDecoder is
   port(
      COLOR3: in std_logic_vector(2 downto 0);
      RGB24: out std_logic_vector(23 downto 0)
   );
end ColorDecoder;

architecture beh of ColorDecoder is
   signal R, G, B: std_logic_vector(7 downto 0);
begin

   R <= COLOR3(2) & "0000000";
   G <= COLOR3(1) & "0000000";
   B <= COLOR3(0) & "0000000";
   RGB24 <= R & G & B;

end beh;

