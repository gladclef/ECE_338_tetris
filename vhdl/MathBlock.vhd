-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Rachel Cazolla, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    MathBlock - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Tracks a math block and renders its pixels.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
-----------------------------------------------------------
-- FSM created with https://github.com/gladclef/FSMs
-- {'fsm_name':'MathBlock','table_vals':[['', 'reset', 'start', '__', '___', 'text_ready', 'stop', 'off_screen'], ['IDLE', '', 'LOAD', '', '', '', '', ''], ['LOAD', '', '', 'ASCII_START', '', '', '', ''], ['ASCII_START', '', '', '', 'ASCII_WAIT', '', '', ''], ['ASCII_WAIT', '', '', '', '', 'RENDER', '', ''], ['RENDER', '', '', '', '', '', 'IDLE', 'IDLE']]}
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity MathBlock is
   Port (
      reset : in std_logic;
      clk : in std_logic;
      start: in std_logic;
      ready: out std_logic;
      x: in std_logic_vector(10 downto 0);
      ascii: in std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
      y_increment: in std_logic;
      stop: in std_logic;
      pix_x: in std_logic_vector(10 downto 0);
      pix_y: in std_logic_vector(9 downto 0);
      pix_en: out std_logic
   );
end MathBlock;

architecture rtl of MathBlock is
   type state_type is (IDLE, LOAD, ASCII_START, ASCII_WAIT, RENDER);
   type characters is array(0 to MATH_BLOCK_MAX_CHARS-1) of ascii_char;
   
   signal state_reg, state_next: state_type;
   signal block_x_reg, block_x_next: integer range 0 to 1023;
   signal block_y_reg, block_y_next: integer range 0 to 511;
   signal ascii_reg, ascii_next: characters;
   -- TODO include render_nextx and render_nexty registers
   -- TODO include render_bits registers
   signal text_ready: std_logic;
   signal off_screen: std_logic;

begin

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg <= IDLE;
         block_x_reg <= 0;
         block_y_reg <= 1023;
         ascii_reg <= (others => (others => '0'));
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
         block_x_reg <= block_x_next;
         block_y_reg <= block_y_next;
         ascii_reg <= ascii_next;
      end if;
   end process;

   off_screen <= '1' when (block_y_reg > 479) else '0';
   ready <= '1' when state_reg = IDLE else '0';

   -- combinational circuit
   process(state_reg, reset, start, text_ready, stop, off_screen)
   begin
      state_next <= state_reg;
      block_x_next <= block_x_reg;
      block_y_next <= block_y_reg;
      ascii_next <= ascii_reg;

      case state_reg is
         when IDLE =>
            if (start = '1') then
               state_next <= LOAD;
            end if;

         when LOAD =>
            for i in 0 to MATH_BLOCK_MAX_CHARS loop
               ascii_next(i) <= ascii((i+1)*8 downto i*8);
            end loop;
            state_next <= ASCII_START;

         when ASCII_START =>
            text_start <= '1';
            state_next <= ASCII_WAIT;

         when ASCII_WAIT =>
            if (text_ready = '1') then
               state_next <= RENDER;
            end if;

         when RENDER =>
            if (stop = '1') then
               state_next <= IDLE;
            elsif (off_screen = '1') then
               state_next <= IDLE;
            end if;

      end case;
   end process;
end rtl;
