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
-- Description:    Renders the given characters as a matrix of 0's and 1's, to be interpreted as pixels.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
-----------------------------------------------------------
-- FSM created with https://github.com/gladclef/FSMs
-- {'fsm_name': 'RenderText', 'table_vals': [['', 'reset', 'start', '__', 'has_char', '___'], ['IDLE', '', 'COUNT_CHARS', '', '', ''], ['COUNT_CHARS', '', '', 'RENDER', '', ''], ['RENDER', '', '', '', 'RENDER_CHAR', 'IDLE'], ['RENDER_CHAR', '', '', '', '', 'RENDER']]}
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
      count:  out std_logic_vector(MATH_BLOCK_MAX_CHARS_NB-1 downto 0);
      pixels: out std_logic_vector(0 to TEXT_BLOCK_ADDR-1);
      ready:  out std_logic
   );
end RenderText;

architecture rtl of RenderText is
   CONSTANT CHAR_0 : std_logic_vector(0 to 14) := "111101101101111";
   CONSTANT CHAR_1 : std_logic_vector(0 to 14) := "010010010010010";
   CONSTANT CHAR_2 : std_logic_vector(0 to 14) := "111001111100111";
   CONSTANT CHAR_3 : std_logic_vector(0 to 14) := "111001111001111";
   CONSTANT CHAR_4 : std_logic_vector(0 to 14) := "101101111001001";
   CONSTANT CHAR_5 : std_logic_vector(0 to 14) := "111100111001111";
   CONSTANT CHAR_6 : std_logic_vector(0 to 14) := "111100111101111";
   CONSTANT CHAR_7 : std_logic_vector(0 to 14) := "111001001001001";
   CONSTANT CHAR_8 : std_logic_vector(0 to 14) := "111101111101111";
   CONSTANT CHAR_9 : std_logic_vector(0 to 14) := "111101111001001";
   CONSTANT CHAR_MUL : std_logic_vector(0 to 14) := "000101010101000";
   CONSTANT CHAR_PLU : std_logic_vector(0 to 14) := "000010111010000";
   CONSTANT CHAR_MIN : std_logic_vector(0 to 14) := "000000011000000";
   CONSTANT CHAR_DIV : std_logic_vector(0 to 14) := "001001010100100";
   CONSTANT CHAR_EQU : std_logic_vector(0 to 14) := "000011000011000";

   CONSTANT ROW0 : integer := TEXT_BLOCK_WIDTH*0;
   CONSTANT ROW1 : integer := TEXT_BLOCK_WIDTH*1;
   CONSTANT ROW2 : integer := TEXT_BLOCK_WIDTH*2;
   CONSTANT ROW3 : integer := TEXT_BLOCK_WIDTH*3;
   CONSTANT ROW4 : integer := TEXT_BLOCK_WIDTH*4;
   
   type state_type is (IDLE, COUNT_CHARS, RENDER, RENDER_CHAR);

   signal state_reg, state_next: state_type;
   signal idx_reg, idx_next: integer range 0 to MATH_BLOCK_MAX_CHARS;
   signal count_reg, count_next: integer range 0 to MATH_BLOCK_MAX_CHARS;
   signal render_x_reg, render_x_next: integer range 0 to TEXT_BLOCK_WIDTH+4;
   signal pixels_reg, pixels_next: std_logic_vector(0 to TEXT_BLOCK_ADDR-1);

   signal ascii_val_debug: std_logic_vector(ASCII_NB-1 downto 0);
begin

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg <= IDLE;
         idx_reg <= 0;
         count_reg <= 0;
         render_x_reg <= 0;
         pixels_reg <= (others => '0');
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
         idx_reg <= idx_next;
         count_reg <= count_next;
         render_x_reg <= render_x_next;
         pixels_reg <= pixels_next;
      end if;
   end process;

   -- combinational circuit
   process(state_reg, reset, start, ascii, idx_reg, count_reg, render_x_reg)
      variable char_bits : std_logic_vector(0 to 14);
      variable ascii_val : std_logic_vector(ASCII_NB-1 downto 0);
   begin
      state_next <= state_reg;
      idx_next <= idx_reg;
      count_next <= count_reg;
      render_x_next <= render_x_reg;
      pixels_next <= pixels_reg;
      ready <= '0';

      ascii_val_debug <= (others => '0');

      case state_reg is
         when IDLE =>
            ready <= '1';
            if (start = '1') then
               state_next <= COUNT_CHARS;
               idx_next <= 0;
               count_next <= 0;
               render_x_next <= 0;
            end if;

         when COUNT_CHARS =>
            -- check for a character at the given position
            ascii_val := ascii((idx_reg+1)*ASCII_NB-1 downto idx_reg*ASCII_NB);
            if (ascii_val /= ASCII_NUL) then
               count_next <= idx_reg+1;
            end if;

            if (idx_reg = MATH_BLOCK_MAX_CHARS-1) then
               -- go to the next state once we've counted all the characters
               idx_next <= 0;
               state_next <= RENDER;
            else
               idx_next <= idx_reg+1;
            end if;

         when RENDER =>
            if (idx_reg < count_reg) then
               state_next <= RENDER_CHAR;
            else
               state_next <= IDLE;
            end if;

         when RENDER_CHAR =>
            ascii_val := ascii((idx_reg+1)*ASCII_NB-1 downto idx_reg*ASCII_NB);
            ascii_val_debug <= ascii_val;
            if (ascii_val = ASCII_0) then
               char_bits(0 to 14) := CHAR_0(0 to 14);
            elsif (ascii_val = ASCII_1) then
               char_bits(0 to 14) := CHAR_1(0 to 14);
            elsif (ascii_val = ASCII_2) then
               char_bits(0 to 14) := CHAR_2(0 to 14);
            elsif (ascii_val = ASCII_3) then
               char_bits(0 to 14) := CHAR_3(0 to 14);
            elsif (ascii_val = ASCII_4) then
               char_bits(0 to 14) := CHAR_4(0 to 14);
            elsif (ascii_val = ASCII_5) then
               char_bits(0 to 14) := CHAR_5(0 to 14);
            elsif (ascii_val = ASCII_6) then
               char_bits(0 to 14) := CHAR_6(0 to 14);
            elsif (ascii_val = ASCII_7) then
               char_bits(0 to 14) := CHAR_7(0 to 14);
            elsif (ascii_val = ASCII_8) then
               char_bits(0 to 14) := CHAR_8(0 to 14);
            elsif (ascii_val = ASCII_9) then
               char_bits(0 to 14) := CHAR_9(0 to 14);
            elsif (ascii_val = ASCII_MUL) then
               char_bits(0 to 14) := CHAR_MUL(0 to 14);
            elsif (ascii_val = ASCII_PLU) then
               char_bits(0 to 14) := CHAR_PLU(0 to 14);
            elsif (ascii_val = ASCII_MIN) then
               char_bits(0 to 14) := CHAR_MIN(0 to 14);
            elsif (ascii_val = ASCII_DIV) then
               char_bits(0 to 14) := CHAR_DIV(0 to 14);
            elsif (ascii_val = ASCII_EQU) then
               char_bits(0 to 14) := CHAR_EQU(0 to 14);
            end if;

            pixels_next(render_x_reg+ROW0 to render_x_reg+ROW0+2) <= char_bits(0 to 2);
            pixels_next(render_x_reg+ROW1 to render_x_reg+ROW1+2) <= char_bits(3 to 5);
            pixels_next(render_x_reg+ROW2 to render_x_reg+ROW2+2) <= char_bits(6 to 8);
            pixels_next(render_x_reg+ROW3 to render_x_reg+ROW3+2) <= char_bits(9 to 11);
            pixels_next(render_x_reg+ROW4 to render_x_reg+ROW4+2) <= char_bits(12 to 14);

            idx_next <= idx_reg + 1;
            render_x_next <= render_x_reg + 4;
            state_next <= RENDER;

      end case;
   end process;

   pixels <= pixels_reg;
   count <= std_logic_vector(to_unsigned(count_reg,count'length));
end rtl;
