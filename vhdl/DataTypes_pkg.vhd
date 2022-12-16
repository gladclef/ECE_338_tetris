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

   CONSTANT SCREEN_WIDTH : integer := 640;
   CONSTANT SCREEN_HEIGHT : integer := 480;
   CONSTANT SCREEN_WIDTH_NB : integer := 11;
   CONSTANT SCREEN_HEIGHT_NB : integer := 10;
   CONSTANT SCREEN_WIDTH_MAX : integer := 2**SCREEN_WIDTH_NB; -- 1024 = 2^SCREEN_WIDTH_NB
   CONSTANT SCREEN_HEIGHT_MAX : integer := 2**SCREEN_HEIGHT_NB; -- 512 = 2^SCREEN_HEIGHT_NB
   CONSTANT SCREEN_ADDR_NB : integer := 19; -- 640x480=307200, log(307200)=19

   CONSTANT COLOR_BLACK : std_logic_vector(23 downto 0) := (others => '0');
   CONSTANT COLOR_WHITE : std_logic_vector(23 downto 0) := (others => '1');
   CONSTANT COLOR_RED   : std_logic_vector(23 downto 0) := std_logic_vector(to_unsigned( 255*65536 + 0*256   + 0,   24 ));
   CONSTANT COLOR_GREEN : std_logic_vector(23 downto 0) := std_logic_vector(to_unsigned( 0*65536   + 0*256   + 255, 24 ));
   CONSTANT COLOR_BLUE  : std_logic_vector(23 downto 0) := std_logic_vector(to_unsigned( 0*65536   + 255*256 + 0,   24 ));
   CONSTANT COLOR_PURPLE : std_logic_vector(23 downto 0) := std_logic_vector(to_unsigned( 255*65536 + 255*256 + 0,  24 ));

   CONSTANT MATH_BLOCK_MAX_CHARS_NB : integer := 4;
   CONSTANT MATH_BLOCK_MAX_CHARS : integer := 8;
   CONSTANT TEXT_BLOCK_WIDTH : integer := MATH_BLOCK_MAX_CHARS*4;
   CONSTANT TEXT_BLOCK_HEIGHT : integer := 5;
   CONSTANT TEXT_BLOCK_ADDR : integer := TEXT_BLOCK_WIDTH*TEXT_BLOCK_HEIGHT;
   CONSTANT MATH_BLOCK_MAX_WIDTH : integer  := TEXT_BLOCK_WIDTH+5; -- +6, -1 for the extra space after each character
   CONSTANT MATH_BLOCK_HEIGHT : integer := TEXT_BLOCK_HEIGHT+6;
   CONSTANT MAX_FALL_RATE : integer := 30;
   CONSTANT MAX_FALL_RATE_NB : integer := 5;

   CONSTANT ROCKET_WIDTH : integer := 32;
   CONSTANT ROCKET_HEIGHT : integer := 32;
   CONSTANT ROCKET_X : integer := SCREEN_WIDTH/2 - ROCKET_WIDTH/2;
   CONSTANT ROCKET_Y : integer := SCREEN_HEIGHT - ROCKET_HEIGHT;
   CONSTANT ROCKET_MAX_MOVE_RATE : integer := 7;
   CONSTANT ROCKET_MAX_MOVE_RATE_NB : integer := 3;
   CONSTANT ROCKET_ADDR_MAX : integer := 1023; -- ROCKET_WIDTH*ROCKET_HEIGHT-1
   CONSTANT ROCKET_ADDR_NB : integer := 10; -- log(ROCKET_ADDR_MAX)
   
   CONSTANT BULLET_WIDTH : integer := 1;
   CONSTANT BULLET_HEIGHT : integer := 7;
   CONSTANT BULLET_X : integer := SCREEN_WIDTH/2 - ROCKET_WIDTH/2 - BULLET_WIDTH/2;
   CONSTANT BULLET_Y_START : integer := SCREEN_HEIGHT - ROCKET_HEIGHT - BULLET_HEIGHT;
   CONSTANT BULLET_ADDR_MAX : integer := 6; --BULLET_WIDTH*BULLET_HEIGHT-1;
   CONSTANT BULLET_SPEED : integer := 10;

   CONSTANT ASCII_NB : integer := 6;
   CONSTANT ASCII_NUL : std_logic_vector(ASCII_NB-1 downto 0) := (others => '0');
   CONSTANT ASCII_A :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(65-64,ASCII_NB));
   CONSTANT ASCII_B :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(66-64,ASCII_NB));
   CONSTANT ASCII_C :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(67-64,ASCII_NB));
   CONSTANT ASCII_D :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(68-64,ASCII_NB));
   CONSTANT ASCII_E :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(69-64,ASCII_NB));
   CONSTANT ASCII_F :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(70-64,ASCII_NB));
   CONSTANT ASCII_G :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(71-64,ASCII_NB));
   CONSTANT ASCII_H :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(72-64,ASCII_NB));
   CONSTANT ASCII_I :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(73-64,ASCII_NB));
   CONSTANT ASCII_J :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(74-64,ASCII_NB));
   CONSTANT ASCII_K :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(75-64,ASCII_NB));
   CONSTANT ASCII_L :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(76-64,ASCII_NB)); -- 0C
   CONSTANT ASCII_M :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(77-64,ASCII_NB));
   CONSTANT ASCII_N :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(78-64,ASCII_NB));
   CONSTANT ASCII_O :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(79-64,ASCII_NB));
   CONSTANT ASCII_P :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(80-64,ASCII_NB));
   CONSTANT ASCII_Q :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(81-64,ASCII_NB));
   CONSTANT ASCII_R :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(82-64,ASCII_NB));
   CONSTANT ASCII_S :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(83-64,ASCII_NB));
   CONSTANT ASCII_T :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(84-64,ASCII_NB));
   CONSTANT ASCII_U :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(85-64,ASCII_NB));
   CONSTANT ASCII_V :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(86-64,ASCII_NB));
   CONSTANT ASCII_W :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(87-64,ASCII_NB));
   CONSTANT ASCII_X :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(88-64,ASCII_NB));
   CONSTANT ASCII_Y :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(89-64,ASCII_NB));
   CONSTANT ASCII_Z :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(90-64,ASCII_NB));
   CONSTANT ASCII_MUL : std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(28,ASCII_NB)); -- 1C
   CONSTANT ASCII_PLU : std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(43,ASCII_NB)); -- 2B
   CONSTANT ASCII_MIN : std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(45,ASCII_NB)); -- 2D
   CONSTANT ASCII_DIV : std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(47,ASCII_NB)); -- 2F
   CONSTANT ASCII_0 :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(48,ASCII_NB)); -- 30
   CONSTANT ASCII_1 :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(49,ASCII_NB)); -- 31
   CONSTANT ASCII_2 :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(50,ASCII_NB)); -- 32
   CONSTANT ASCII_3 :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(51,ASCII_NB)); -- 33
   CONSTANT ASCII_4 :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(52,ASCII_NB)); -- 34
   CONSTANT ASCII_5 :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(53,ASCII_NB)); -- 35
   CONSTANT ASCII_6 :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(54,ASCII_NB)); -- 36
   CONSTANT ASCII_7 :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(55,ASCII_NB)); -- 37
   CONSTANT ASCII_8 :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(56,ASCII_NB)); -- 38
   CONSTANT ASCII_9 :   std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(57,ASCII_NB)); -- 39
   CONSTANT ASCII_CLN : std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(58,ASCII_NB)); -- 3A
   CONSTANT ASCII_EQU : std_logic_vector(ASCII_NB-1 downto 0) := std_logic_vector(to_unsigned(61,ASCII_NB)); -- 3D

end DataTypes_pkg;
