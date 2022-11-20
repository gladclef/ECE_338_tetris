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
-- {'fsm_name': 'MathBlock', 'table_vals': [['', 'reset', 'start', '__', '___', 'text_ready', 'v_back_porch', 'v_front_port', 'stop', 'off_screen'], ['IDLE', '', 'ASCII_START', '', '', '', '', '', '', ''], ['ASCII_START', '', '', '', 'ASCII_WAIT', '', '', '', '', ''], ['ASCII_WAIT', '', '', '', '', 'RENDER', '', '', '', ''], ['RENDER', '', '', '', '', '', 'INTER_FRAME', '', 'IDLE', 'IDLE'], ['INTER_FRAME', '', '', '', '', '', '', 'RENDER', 'IDLE', 'IDLE']]}
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity MathBlock is
   Port (
      reset:       in std_logic;
      clk:         in std_logic;
      ready:       out std_logic;
      start:       in std_logic;
      x:           in std_logic_vector(10 downto 0);
      ascii:       in std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
      y_increment: in std_logic_vector(MAX_FALL_RATE_NB-1 downto 0);
      stop:        in std_logic;
      pix_x:       in std_logic_vector(10 downto 0);
      pix_y:       in std_logic_vector(9 downto 0);
      pix_en:      out std_logic;
      color:       out std_logic_vector(23 downto 0)
   );
end MathBlock;

architecture rtl of MathBlock is
   CONSTANT V_BACK_PORCH_VEC:  std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(480,10));
   CONSTANT V_FRONT_PORCH_VEC: std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(481,10));
   type state_type is (IDLE, ASCII_START, ASCII_WAIT, RENDER, INTER_FRAME);

   signal state_reg, state_next: state_type;
   signal block_x_reg, block_x_next: integer range 0 to 1023;
   signal block_y_reg, block_y_next: integer range 0 to 511;
   signal ascii_reg, ascii_next: std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
   signal text_width_reg, text_width_next: integer range 0 to 1023;
   signal text_start: std_logic;
   signal text_ready: std_logic;
   signal text_count: std_logic_vector(MATH_BLOCK_MAX_CHARS_NB-1 downto 0);
   signal text_pixels: std_logic_vector(0 to TEXT_BLOCK_ADDR-1);
   signal v_back_porch, v_front_porch: std_logic;
   signal off_screen: std_logic;

begin

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg <= IDLE;
         block_x_reg <= 0;
         block_y_reg <= 0;
         ascii_reg <= (others => '0');
         text_width_reg <= 0;
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
         block_x_reg <= block_x_next;
         block_y_reg <= block_y_next;
         ascii_reg <= ascii_next;
         text_width_reg <= text_width_next;
      end if;
   end process;

   v_back_porch <= '1' when (pix_y = V_BACK_PORCH_VEC) else '0';
   v_front_porch <= '1' when (pix_y = V_FRONT_PORCH_VEC) else '0';
   off_screen <= '1' when (block_y_reg > 479) else '0';
   ready <= '1' when state_reg = IDLE else '0';
   color <= COLOR_WHITE;

   -- combinational circuit
   process(state_reg, reset, start, ascii, text_count, text_ready, pix_x, pix_y, block_x_reg, block_y_reg, text_width_reg, text_pixels, y_increment, v_back_porch, v_front_porch, stop, off_screen)
      variable pix_x_int: integer range 0 to 1023;
      variable pix_y_int: integer range 0 to 511;
   begin
      state_next <= state_reg;
      block_x_next <= block_x_reg;
      block_y_next <= block_y_reg;
      ascii_next <= ascii_reg;
      text_width_next <= text_width_reg;
      text_start <= '0';
      pix_en <= '0';

      case state_reg is
         when IDLE =>
            if (start = '1') then
               ascii_next <= ascii;
               state_next <= ASCII_START;
            end if;

         when ASCII_START =>
            -- give the RenderText component a clock cycle to get started
            text_start <= '1';
            state_next <= ASCII_WAIT;

         when ASCII_WAIT =>
            -- busy wait for the RenderText component to finish generating its bits
            text_width_next <= to_integer(unsigned(text_count)) * 4;
            if (text_ready = '1') then
               state_next <= RENDER;
            end if;

         when RENDER =>
            pix_x_int := to_integer(unsigned(pix_x));
            pix_y_int := to_integer(unsigned(pix_y));

            -- render out the border as it comes up
            if (pix_y_int >= block_y_reg and pix_y_int <= block_y_reg+MATH_BLOCK_HEIGHT-1) then
               if (pix_x_int = block_x_reg) then                         -- left border
                  pix_en <= '1';
               end if;
               if (pix_x_int = block_x_reg+text_width_reg+5-1) then      -- right border
                  pix_en <= '1';
               end if;
               if (pix_x_int > block_x_reg and pix_x_int < block_x_reg+text_width_reg+5) then
                   if (pix_y_int = block_y_reg) then                     -- top border
                      pix_en <= '1';
                   end if;
                   if (pix_y_int = block_y_reg+MATH_BLOCK_HEIGHT-1) then -- bottom border
                      pix_en <= '1';
                   end if;
               end if;
            end if;

            -- render out the text bits as they come up
            for i in 0 to TEXT_BLOCK_HEIGHT-1 loop
               if (pix_y_int = block_y_reg+3+i) then -- in the text row
                  if (pix_x_int > block_x_reg+2 and pix_x_int < block_x_reg+text_width_reg+4) then -- in the text block
                     pix_en <= text_pixels(TEXT_BLOCK_WIDTH*i + pix_x_int-block_x_reg-3);
                  end if;
               end if;
            end loop;

            if (v_back_porch = '1') then
               state_next <= INTER_FRAME;
            elsif (stop = '1') then
               state_next <= IDLE;
            elsif (off_screen = '1') then
               state_next <= IDLE;
            end if;

         when INTER_FRAME =>
            -- single clock cycle frame intermission to increment the block_y_reg
            block_y_next <= block_y_reg + to_integer(unsigned(y_increment));

            if (v_front_porch = '1') then
               state_next <= RENDER;
            elsif (stop = '1') then
               state_next <= IDLE;
            elsif (off_screen = '1') then
               state_next <= IDLE;
            end if;

      end case;
   end process;

   render_text: entity work.RenderText(rtl)
   port map (
      reset  => reset,
      clk    => clk,
      start  => text_start,
      ascii  => ascii_reg,
      count  => text_count,
      pixels => text_pixels,
      ready  => text_ready
   );
end rtl;
