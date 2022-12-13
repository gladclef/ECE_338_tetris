----------------------------------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Rachel Cazolla, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    DrawActive - Behavioral 
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

-- DrawActive chooses which pixel to draw to the scene, based on the priority ordering:
-- * special effects
-- * player's ship
-- * bullets
-- * presents
-- * math blocks

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

library work;
use work.DataTypes_pkg.all;

entity DrawActive is
   port(
      pix_en: in std_logic;
      background_color: in std_logic_vector(23 downto 0);
      --special_en: in std_logic;
      --special_color: in std_logic_vector(23 downto 0);
      rocket_en: in std_logic;
      rocket_color: in std_logic_vector(23 downto 0);
      --bullet_en: in std_logic;
      --bullet_color: in std_logic_vector(23 downto 0);
      --present_en: in std_logic;
      --present_color: in std_logic_vector(23 downto 0);
      math_block_en: in std_logic;
      math_block_color: in std_logic_vector(23 downto 0);
      livesAndScoreColor: in std_logic_vector(23 downto 0);
      livesAndScore_en: in std_logic;
      bullet_en: in std_logic;
      bullet_color: in std_logic_vector(23 downto 0);
      color_out: out std_logic_vector(23 downto 0)
   );
end DrawActive;

architecture beh of DrawActive is
begin

   color_out <= COLOR_BLACK when pix_en = '0' else
                rocket_color when rocket_en = '1' else
                math_block_color when math_block_en = '1' else
                livesAndScoreColor when livesAndScore_en = '1' else
                bullet_color when bullet_en = '1' else
                background_color;

end beh;

