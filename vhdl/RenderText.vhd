-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Rachel Cazolla, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    RenderText - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Renders the given characters as a matrix of 0's and 1's, to be interpretted as pixels.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
-----------------------------------------------------------
-- FSM created with https://github.com/gladclef/FSMs
-- {'fsm_name': 'RenderText', 'table_vals': [['', 'reset', 'start', 'has_char', '__'], ['IDLE', '', 'COUNT', '', ''], ['COUNT', '', '', 'RENDER', ''], ['RENDER', '', '', 'RENDER_CHAR', 'IDLE'], ['RENDER_CHAR', '', '', '', 'RENDER']]}
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity RenderText is
   Port (
      reset:  in std_logic;
      clk:    in std_logic;
      start:  in std_logic;
      ascii:  in std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
      pixels: out std_logic_vector(0 to TEXT_BLOCK_ADDR-1);
      ready:  out std_logic
   );
end RenderText;

architecture rtl of RenderText is
   type state_type is (IDLE, COUNT, RENDER, RENDER_CHAR);
   CONSTANT char_0 : std_logic_vector(0 to 14) := "111101101101111";
   CONSTANT char_1 : std_logic_vector(0 to 14) := "010010010010010";
   CONSTANT char_2 : std_logic_vector(0 to 14) := "111001111100111";
   CONSTANT char_3 : std_logic_vector(0 to 14) := "111001111001111";
   CONSTANT char_4 : std_logic_vector(0 to 14) := "101101111001001";
   CONSTANT char_5 : std_logic_vector(0 to 14) := "111100111001111";
   CONSTANT char_6 : std_logic_vector(0 to 14) := "111100111101111";
   CONSTANT char_7 : std_logic_vector(0 to 14) := "111001001001001";
   CONSTANT char_8 : std_logic_vector(0 to 14) := "111101111101111";
   CONSTANT char_9 : std_logic_vector(0 to 14) := "111101111001001";
   CONSTANT char_equ : std_logic_vector(0 to 14) := "000011000011000";
   CONSTANT char_plu : std_logic_vector(0 to 14) := "000010111010000";
   CONSTANT char_min : std_logic_vector(0 to 14) := "000000011000000";
   CONSTANT char_div : std_logic_vector(0 to 14) := "001001010100100";
   CONSTANT char_mul : std_logic_vector(0 to 14) := "000101010101000";

   signal state_reg, state_next: state_type;
   signal has_char: std_logic;
begin

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg <= IDLE;
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
      end if;
   end process;

   -- combinational circuit
   process(state_reg, reset, start, has_char, __)
   begin
      state_next <= state_reg;

      case state_reg is
         when IDLE =>
            -- state logic
            if (start = '1') then
               state_next <= COUNT;
            end if;

         when COUNT =>
            -- state logic
            if (has_char = '1') then
               state_next <= RENDER;
            end if;

         when RENDER =>
            -- state logic
            if (has_char = '1') then
               state_next <= RENDER_CHAR;
            else
               state_next <= IDLE;
            end if;

         when RENDER_CHAR =>
            -- state logic
            state_next <= RENDER;

      end case;
   end process;
end rtl;
