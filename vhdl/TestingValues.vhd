-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Rachel Cazzola, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    TestingValues - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Includes basic debugging values and code.
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

entity TestingValues is
   Port (
      start:              out std_logic;
      math_block_start_x: out std_logic_vector(SCREEN_WIDTH_NB-1 downto 0);
      ex4p5e9:            out std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
      y_increment:        out std_logic_vector(MAX_FALL_RATE_NB-1 downto 0);
      stop:               out std_logic;
      x_increment:        out std_logic_vector(ROCKET_MAX_MOVE_RATE_NB downto 0); -- signed, include an extra bit for negatives
      color_black:        out std_logic_vector(2 downto 0)
   );
end TestingValues;

architecture rtl of TestingValues is
begin

   start <= '1';
   math_block_start_x <= "11100011000";
   -- 4  +  5  =  9
   -- 52 43 53 61 57
   --x34 2B 35 3D 39
   --                                     9         =           5         +           4
   ex4p5e9 <= "000000"&"000000"&"000000"& ASCII_9 & ASCII_EQU & ASCII_5 & ASCII_PLU & ASCII_4;
   
   y_increment <= "00001";
   stop <= '0';
   x_increment <= (others => '0');
   color_black <= (others => '0');

end rtl;
