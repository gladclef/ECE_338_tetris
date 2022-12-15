-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Rachel Cazzola, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    MathBlock - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Tracks a math block and draws its pixels.
--
-- Dependencies:   RenderText.vhd
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
-----------------------------------------------------------
-- FSM created with https://github.com/gladclef/FSMs
-- {"fsm_name":"MathBlock","table_vals":[["","reset","start","___","text_ready","frame_update","____","stop","off_screen"],["IDLE","","ASCII_START","","","","","",""],["ASCII_START","","","ASCII_WAIT","","","","",""],["ASCII_WAIT","","","","DRAW","","","",""],["DRAW","","","","","INTER_FRAME","","IDLE","IDLE"],["INTER_FRAME","","","","","","DRAW","IDLE","IDLE"]]}
--=========================================================
--
-- Tracks a math block and draws its pixels. This draws the border and text
-- pixels in sync with the pix_x and pix_y inputs by indexing into the text_pixel_mask
-- register.
--
-- When start gets asserted, this latches the x and ascii values, and starts the
-- RenderText module. Once that module is done rendering the ascii string onto
-- the pixel mask, this starts drawing the block.
-- 
-- This module holds the state of a MathBlock, including its x/y position, ascii
-- string, validity, and text pixel map.
-- 
-- On every frame_update, it increments its y position and checks for collisions
-- with the on screen bullet or rocket. If there is a collision, it reports it
-- to the outputs and disables the block.
--
--=========================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity MathBlock is
   Port (
      -- standard signals
      reset:        in std_logic;
      clk:          in std_logic;
      start:        in std_logic;
      stop:         in std_logic;
      ready:        out std_logic;

      -- correctness
      correctness:  in std_logic;
      is_correct:   out std_logic;

      -- where to place the block, and what it should display
      x:            in std_logic_vector(10 downto 0);
      ascii:        in std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);

      -- vertical speed of the block
      y_increment:  in std_logic_vector(MAX_FALL_RATE_NB-1 downto 0);

      -- the pixel that is currently being drawn
      pix_x:        in std_logic_vector(10 downto 0);
      pix_y:        in std_logic_vector(9 downto 0);

      -- math block draw enable for the given pix_x/pix_y, and the color for that pixel
      pix_mb_en:    out std_logic;
      color:        out std_logic_vector(23 downto 0);

      -- the one cycle frame sync at the end of every frame
      frame_update: in std_logic
   );
end MathBlock;

architecture rtl of MathBlock is
   type state_type is (IDLE, ASCII_START, ASCII_WAIT, DRAW, INTER_FRAME);
   signal state_reg, state_next: state_type;

   -- the current x and y locations of the block
   signal block_x_reg, block_x_next: integer range 0 to 1023;
   signal block_y_reg, block_y_next: integer range 0 to 511;
   signal off_screen: std_logic;

   -- latched values when start gets asserted
   signal ascii_reg, ascii_next: std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
   signal is_correct_reg, is_correct_next: std_logic;

   -- signals to and from the RenderText module
   --   render_start:    starts the RenderText module
   --   text_ready:      when the RenderText module is done rendering
   --   text_pixel_mask: the pixels rendered to by RenderText, to be drawn to the screen
   --   text_width:      the number of bits that are occupied on the screen by the rendered text
   --   text_count:      a count of how many characters are in the ascii_reg
   signal render_start: std_logic;
   signal text_ready: std_logic;
   signal text_pixel_mask: std_logic_vector(0 to TEXT_BLOCK_ADDR-1);
   signal text_width_reg, text_width_next: integer range 0 to 1023;
   signal text_count: std_logic_vector(MATH_BLOCK_MAX_CHARS_NB-1 downto 0);

begin

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg <= IDLE;
         block_x_reg <= 0;
         block_y_reg <= 0;
         ascii_reg <= (others => '0');
         is_correct_reg <= '0';
         text_width_reg <= 0;
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
         block_x_reg <= block_x_next;
         block_y_reg <= block_y_next;
         ascii_reg <= ascii_next;
         is_correct_reg <= is_correct_next;
         text_width_reg <= text_width_next;
      end if;
   end process;

   off_screen <= '1' when (block_y_reg = SCREEN_HEIGHT - ROCKET_HEIGHT - MATH_BLOCK_HEIGHT) else '0';
   ready <= '1' when state_reg = IDLE else '0';

   -- combinational circuit
   process(state_reg, reset, start, x, ascii, correctness, ascii_reg, is_correct_reg, text_count, text_ready, pix_x, pix_y, block_x_reg, block_y_reg, text_width_reg, text_pixel_mask, y_increment, frame_update, stop, off_screen)
      variable int_pix_x: integer range 0 to SCREEN_WIDTH_MAX;
      variable int_pix_y: integer range 0 to SCREEN_HEIGHT_MAX;
      variable var_pix_en: std_logic;
   begin
      state_next <= state_reg;
      block_x_next <= block_x_reg;
      block_y_next <= block_y_reg;
      ascii_next <= ascii_reg;
      is_correct_next <= is_correct_reg;
      text_width_next <= text_width_reg;
      render_start <= '0';
      pix_mb_en <= '0';

      color <= COLOR_WHITE;

      case state_reg is
         when IDLE =>
            if (start = '1') then
               -- latch inputs
               block_x_next  <= to_integer(unsigned(x));
               ascii_next <= ascii;
               is_correct_next <= correctness;
               -- start drawing at the top
               block_y_next <= 0;
               -- go render the text
               state_next <= ASCII_START;
            end if;

         when ASCII_START =>
            -- give the RenderText component a clock cycle to get started
            render_start <= '1';
            state_next <= ASCII_WAIT;

         when ASCII_WAIT =>
            -- busy wait for the RenderText component to finish generating its bits
            text_width_next <= to_integer(unsigned(text_count)) * 4;
            if (text_ready = '1') then
               state_next <= DRAW;
            end if;

         when DRAW =>
            int_pix_x := to_integer(unsigned(pix_x));
            int_pix_y := to_integer(unsigned(pix_y));
            var_pix_en := '0';

            -- draw out the border as it comes up
            if (int_pix_y >= block_y_reg and int_pix_y <= block_y_reg+MATH_BLOCK_HEIGHT-1) then
               if (int_pix_x = block_x_reg) then                         -- left border
                  var_pix_en := '1';
               end if;
               if (int_pix_x = block_x_reg+text_width_reg+5-1) then      -- right border
                  var_pix_en := '1';
               end if;
               if (int_pix_x > block_x_reg and int_pix_x < block_x_reg+text_width_reg+5) then
                   if (int_pix_y = block_y_reg) then                     -- top border
                      var_pix_en := '1';
                   end if;
                   if (int_pix_y = block_y_reg+MATH_BLOCK_HEIGHT-1) then -- bottom border
                      var_pix_en := '1';
                   end if;
               end if;

               if (var_pix_en = '1') then
                  if (is_correct_reg = '1') then
                     color <= COLOR_GREEN;
                  else
                     color <= COLOR_RED;
                  end if;
               end if;
            end if;

            -- draw out the text pixels
            -- checks if the pixel mask is '1' for the current pix_x and pix_y
            for row in 0 to TEXT_BLOCK_HEIGHT-1 loop
               if (int_pix_y = block_y_reg+3+row) then -- in the text row
                  if (int_pix_x > block_x_reg+2 and int_pix_x < block_x_reg+text_width_reg+3) then -- in the text block
                     var_pix_en := text_pixel_mask(TEXT_BLOCK_WIDTH*row + int_pix_x-block_x_reg-3);
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

            pix_mb_en <= var_pix_en;

         when INTER_FRAME =>
            -- single clock cycle frame intermission to increment the block_y_reg
            block_y_next <= block_y_reg + to_integer(unsigned(y_increment));
            state_next <= DRAW;

            if (stop = '1') then
               state_next <= IDLE;
            elsif (off_screen = '1') then
               state_next <= IDLE;
            end if;

      end case;
   end process;

   is_correct <= is_correct_reg;

   render_text: entity work.RenderText(rtl)
   port map (
      reset  => reset,
      clk    => clk,
      start  => render_start,
      ascii  => ascii_reg,
      count  => text_count,
      pixels => text_pixel_mask,
      ready  => text_ready
   );
end rtl;
