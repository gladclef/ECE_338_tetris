-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Rachel Cazolla, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    Controls - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Manages the control logic based on button input.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity Controls is
   Port (
      zybo_button_left:  in std_logic;
      zybo_button_right: in std_logic;
      x_increment:       out std_logic_vector(ROCKET_MAX_MOVE_RATE_NB downto 0) -- signed, include an extra bit for negatives
   );
end Controls;

architecture rtl of Controls is
begin

   x_increment <= std_logic_vector(to_signed(1,x_increment'length)) when zybo_button_right = '1' else
                  std_logic_vector(to_signed(-1,x_increment'length)) when zybo_button_left = '1' else
                  (others => '0');

end rtl;
