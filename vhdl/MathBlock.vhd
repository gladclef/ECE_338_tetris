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
-- {"fsm_name":"MathBlock","table_vals":[["","reset","start","___","text_ready","frame_update","____","stop","off_screen"],["IDLE","","ASCII_START","","","","","",""],["ASCII_START","","","ASCII_WAIT","","","","",""],["ASCII_WAIT","","","","RENDER","","","",""],["RENDER","","","","","INTER_FRAME","","IDLE","IDLE"],["INTER_FRAME","","","","","","RENDER","IDLE","IDLE"]]}
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity MathBlock is
   Port (
      reset:        in std_logic;
      clk:          in std_logic;
      ready:        out std_logic;
      start:        in std_logic;
      x:            in std_logic_vector(10 downto 0);
      ascii:        in std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
      y_increment:  in std_logic_vector(MAX_FALL_RATE_NB-1 downto 0);
      stop:         in std_logic;
      pix_x:        in std_logic_vector(10 downto 0);
      pix_y:        in std_logic_vector(9 downto 0);
      frame_update: in std_logic;
      pix_mb_en:    out std_logic;
      color:        out std_logic_vector(23 downto 0)
   );
end MathBlock;

architecture rtl of MathBlock is
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

   off_screen <= '1' when (block_y_reg > 479) else '0';
   ready <= '1' when state_reg = IDLE else '0';
   color <= COLOR_WHITE;

   -- combinational circuit
   process(state_reg, reset, start, ascii, text_count, text_ready, pix_x, pix_y, block_x_reg, block_y_reg, text_width_reg, text_pixels, y_increment, frame_update, stop, off_screen)
      variable pix_x_int: integer range 0 to SCREEN_WIDTH_MAX;
      variable pix_y_int: integer range 0 to SCREEN_HEIGHT_MAX;
   begin
      state_next <= state_reg;
      block_x_next <= block_x_reg;
      block_y_next <= block_y_reg;
      ascii_next <= ascii_reg;
      text_width_next <= text_width_reg;
      text_start <= '0';
      pix_mb_en <= '0';

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

            -- draw out the border as it comes up
            if (pix_y_int >= block_y_reg and pix_y_int <= block_y_reg+MATH_BLOCK_HEIGHT-1) then
               if (pix_x_int = block_x_reg) then                         -- left border
                  pix_mb_en <= '1';
               end if;
               if (pix_x_int = block_x_reg+text_width_reg+5-1) then      -- right border
                  pix_mb_en <= '1';
               end if;
               if (pix_x_int > block_x_reg and pix_x_int < block_x_reg+text_width_reg+5) then
                   if (pix_y_int = block_y_reg) then                     -- top border
                      pix_mb_en <= '1';
                   end if;
                   if (pix_y_int = block_y_reg+MATH_BLOCK_HEIGHT-1) then -- bottom border
                      pix_mb_en <= '1';
                   end if;
               end if;
            end if;

            -- draw out the text bits as they come up
            for i in 0 to TEXT_BLOCK_HEIGHT-1 loop
               if (pix_y_int = block_y_reg+3+i) then -- in the text row
                  if (pix_x_int > block_x_reg+2 and pix_x_int < block_x_reg+text_width_reg+4) then -- in the text block
                     pix_mb_en <= text_pixels(TEXT_BLOCK_WIDTH*i + pix_x_int-block_x_reg-3);
                  end if;
               end if;
            end loop;

            if (frame_update = '1') then
               state_next <= INTER_FRAME;
            elsif (stop = '1') then
               state_next <= IDLE;
            elsif (off_screen = '1') then
               state_next <= IDLE;
            end if;

         when INTER_FRAME =>
            -- single clock cycle frame intermission to increment the block_y_reg
            block_y_next <= block_y_reg + to_integer(unsigned(y_increment));
            state_next <= RENDER;

            if (stop = '1') then
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
