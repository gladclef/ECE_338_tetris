----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Rachel Cazzola, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    DataTypes_pkg - Behavioral 
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

package DataTypes_pkg is

   constant MATH_BLOCK_MAX_CHARS : integer := 8;
   constant TEXT_BLOCK_WIDTH : integer := MATH_BLOCK_MAX_CHARS*4;
   constant TEXT_BLOCK_HEIGHT : integer := 5;
   constant TEXT_BLOCK_ADDR : integer := TEXT_BLOCK_WIDTH*TEXT_BLOCK_HEIGHT;
    
   constant ASCII_NB : integer := 7;
   subtype ascii_char is std_logic_vector(6 downto 0);

end DataTypes_pkg;
