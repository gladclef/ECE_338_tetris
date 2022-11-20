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
-- {"fsm_name":"RenderText","table_vals":[["","reset","start","has_char","__"],["IDLE","","RENDER","",""],["RENDER","","","RENDER_CHAR","IDLE"],["RENDER_CHAR","","","","RENDER"]]}
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
   type state_type is (IDLE, RENDER, RENDER_CHAR);
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
   CONSTANT char_mul : std_logic_vector(0 to 14) := "000101010101000";
   CONSTANT char_plu : std_logic_vector(0 to 14) := "000010111010000";
   CONSTANT char_min : std_logic_vector(0 to 14) := "000000011000000";
   CONSTANT char_div : std_logic_vector(0 to 14) := "001001010100100";
   CONSTANT char_equ : std_logic_vector(0 to 14) := "000011000011000";

   CONSTANT row0 : integer := TEXT_BLOCK_WIDTH*0;
   CONSTANT row1 : integer := TEXT_BLOCK_WIDTH*1;
   CONSTANT row2 : integer := TEXT_BLOCK_WIDTH*2;
   CONSTANT row3 : integer := TEXT_BLOCK_WIDTH*3;
   CONSTANT row4 : integer := TEXT_BLOCK_WIDTH*4;

   signal state_reg, state_next: state_type;
   signal idx_reg, idx_next: integer range 0 to MATH_BLOCK_MAX_CHARS;
   signal count_reg, count_next: integer range 0 to MATH_BLOCK_MAX_CHARS-1;
   signal render_x_reg, render_x_next: integer range 0 to TEXT_BLOCK_WIDTH+4;
   signal pixels_reg, pixels_next: std_logic_vector(0 to TEXT_BLOCK_ADDR-1);
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
   process(state_reg, reset, start)
      variable pix_start : integer;
      variable ascii_val : std_logic_vector(ASCII_NB-1 downto 0);
      variable char_bits : std_logic_vector(0 to 14);
   begin
      state_next <= state_reg;
      idx_next <= idx_reg;
      count_next <= count_reg;
      render_x_next <= render_x_reg;
      ready <= '0';

      case state_reg is
         when IDLE =>
            ready <= '1';
            if (start = '1') then
               state_next <= RENDER;
               idx_next <= 0;
               render_x_next <= 0;
            end if;
            for i in 0 to MATH_BLOCK_MAX_CHARS loop
               if (ascii((i+1)*ASCII_NB-1 downto i*ASCII_NB) /= ASCII_NUL) then
                  count_next <= i+1;
               end if;
            end loop;

         when RENDER =>
            if (idx_reg < count_reg) then
               state_next <= RENDER_CHAR;
            else
               state_next <= IDLE;
            end if;

         when RENDER_CHAR =>
            ascii_val := ascii((idx_reg+1)*ASCII_NB-1 downto idx_reg*ASCII_NB);
            if (ascii_val = ASCII_0) then
               char_bits(0 to 14) := ascii_0(0 to 14);
            elsif (ascii_val = ASCII_1) then
               char_bits(0 to 14) := ascii_1(0 to 14);
            elsif (ascii_val = ASCII_2) then
               char_bits(0 to 14) := ascii_2(0 to 14);
            elsif (ascii_val = ASCII_3) then
               char_bits(0 to 14) := ascii_3(0 to 14);
            elsif (ascii_val = ASCII_4) then
               char_bits(0 to 14) := ascii_4(0 to 14);
            elsif (ascii_val = ASCII_5) then
               char_bits(0 to 14) := ascii_5(0 to 14);
            elsif (ascii_val = ASCII_6) then
               char_bits(0 to 14) := ascii_6(0 to 14);
            elsif (ascii_val = ASCII_7) then
               char_bits(0 to 14) := ascii_7(0 to 14);
            elsif (ascii_val = ASCII_8) then
               char_bits(0 to 14) := ascii_8(0 to 14);
            elsif (ascii_val = ASCII_9) then
               char_bits(0 to 14) := ascii_9(0 to 14);
            elsif (ascii_val = ASCII_MUL) then
               char_bits(0 to 14) := ascii_mul(0 to 14);
            elsif (ascii_val = ASCII_PLU) then
               char_bits(0 to 14) := ascii_plu(0 to 14);
            elsif (ascii_val = ASCII_MIN) then
               char_bits(0 to 14) := ascii_min(0 to 14);
            elsif (ascii_val = ASCII_DIV) then
               char_bits(0 to 14) := ascii_div(0 to 14);
            elsif (ascii_val = ASCII_EQU) then
               char_bits(0 to 14) := ascii_equ(0 to 14);
            end if;

            pixels(render_x_reg+row0 to render_x_reg+row0+2) <= char_bits(0 to 2);
            pixels(render_x_reg+row1 to render_x_reg+row1+2) <= char_bits(3 to 5);
            pixels(render_x_reg+row2 to render_x_reg+row2+2) <= char_bits(6 to 8);
            pixels(render_x_reg+row3 to render_x_reg+row3+2) <= char_bits(9 to 11);
            pixels(render_x_reg+row4 to render_x_reg+row4+2) <= char_bits(12 to 14);

            idx_next <= idx_reg + 1;
            render_x_next <= render_x_reg + 4;
            state_next <= RENDER;

      end case;
   end process;

   pixels <= pixels_reg;
end rtl;
