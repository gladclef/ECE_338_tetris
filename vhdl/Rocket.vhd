-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Rachel Cazolla, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    Rocket - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Tracks the player rocket and draws its pixels.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
-----------------------------------------------------------
-- FSM created with https://github.com/gladclef/FSMs
-- {'fsm_name': 'Rocket', 'table_vals': [['', 'reset', 'start', 'stop', 'frame_update', '__'], ['IDLE', '', 'RENDER', '', '', ''], ['RENDER', '', '', 'IDLE', 'INTER_FRAME', ''], ['INTER_FRAME', '', '', '', '', 'RENDER']]}
--=========================================================
--
-- Tracks the rocket and draws its pixels. This does the draw by tracking the
-- draw address for the pixel mask ROM, and drawing the pixels from the ROM
-- while pix_x and pix_y are within the rocket's current x/y borders.
-- The draw address gets incremented every time a pixel is drawn.
-- 
-- This module holds the state of the rocket, which is just the x position.
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

entity Rocket is
   Port (
      reset:         in std_logic;
      clk:           in std_logic;
      start:         in std_logic;
      x_increment:   in std_logic_vector(ROCKET_MAX_MOVE_RATE_NB downto 0); -- signed, include an extra bit for negatives
      pix_x:         in std_logic_vector(SCREEN_WIDTH_NB-1 downto 0);
      pix_y:         in std_logic_vector(SCREEN_HEIGHT_NB-1 downto 0);
      pix_en:        in std_logic;
      frame_update:  in std_logic;
      stop:          in std_logic;
      x_mid:         out std_logic_vector(SCREEN_WIDTH_NB-1 downto 0);
      pix_rocket_en: out std_logic;
      color:         out std_logic_vector(23 downto 0)
   );
end Rocket;

architecture rtl of Rocket is
   type state_type is (IDLE, RENDER, INTER_FRAME);

   signal state_reg, state_next: state_type;
   signal x_reg, x_next: integer range -(SCREEN_WIDTH_MAX-1) to (SCREEN_WIDTH_MAX-1);
   signal draw_addr_reg, draw_addr_next: integer range 0 to ROCKET_ADDR_MAX;
begin

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg <= IDLE;
         x_reg <= 0;--ROCKET_X;
         draw_addr_reg <= 0;
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
         x_reg <= x_next;
         draw_addr_reg <= draw_addr_next;
      end if;
   end process;

   -- combinational circuit
   process(state_reg, reset, start, stop, x_increment, pix_en, pix_x, pix_y, x_reg, frame_update, draw_addr_reg)
      variable rbits: std_logic_vector(0 to ROCKET_ADDR_MAX);
      variable pix_x_int: integer range -(SCREEN_WIDTH_MAX-1) to (SCREEN_WIDTH_MAX-1);
      variable pix_y_int: integer range 0 to SCREEN_HEIGHT_MAX-1;
      variable x_increment_var: integer range -ROCKET_MAX_MOVE_RATE to ROCKET_MAX_MOVE_RATE;
   begin
      state_next <= state_reg;
      x_next <= x_reg;
      draw_addr_next <= draw_addr_reg;
      pix_rocket_en <= '0';

      case state_reg is
         when IDLE =>
            -- state logic
            if (start = '1') then
               state_next <= RENDER;
            end if;

         when RENDER =>
            pix_x_int := to_integer(unsigned(pix_x));
            pix_y_int := to_integer(unsigned(pix_y));

            rbits := "00000000000000010000000000000000" &
                     "00000000000000111000000000000000" &
                     "00000000000000111000000000000000" &
                     "00000000000001111100000000000000" &
                     "00000000000001111100000000000000" &
                     "00000000000011111110000000000000" &
                     "00000000000011111110000000000000" &
                     "00000000000011111110000000000000" &
                     "00000000000111111111000000000000" &
                     "00000000000111111111000000000000" &
                     "00000000000111111111000000000000" &
                     "00000000000111111111000000000000" &
                     "00000000001111111111100000000000" &
                     "00000000001111111111100000000000" &
                     "00000000001111111111100000000000" &
                     "00000000001111111111100000000000" &
                     "00000000001111111111100000000000" &
                     "00000000011111111111110000000000" &
                     "00000000011111111111110000000000" &
                     "00000000111111111111111000000000" &
                     "00000001111111111111111100000000" &
                     "00000011111111111111111110000000" &
                     "00000111111111111111111111000000" &
                     "00000111111111111111111111000000" &
                     "00000111111111111111111111000000" &
                     "00000111111111111111111111000000" &
                     "00000111111111111111111111000000" &
                     "00000111111111111111111111000000" &
                     "00000111111111111111111111000000" &
                     "00000111101111111111101111000000" &
                     "00000111000011111110000111000000" &
                     "00000100000000010000000001000000";

            -- if the line is currently being drawn
            if (pix_en = '1') then
               -- if the y location currently being drawn overlaps the rocket
               if (pix_y_int >= ROCKET_Y and pix_y_int < SCREEN_HEIGHT) then
                  -- if the x location currently being drawn overlaps the rocket
                  if (pix_x_int >= x_reg and pix_x_int < x_reg+ROCKET_WIDTH) then
                     -- draw the rocket!
                     pix_rocket_en <= rbits(draw_addr_reg);
                     if (draw_addr_reg /= ROCKET_ADDR_MAX) then
                        draw_addr_next <= draw_addr_reg + 1;
                     end if;
                  end if;
               end if;
            end if;

            if (stop = '1') then
               state_next <= IDLE;
            elsif (frame_update = '1') then
               state_next <= INTER_FRAME;
            end if;

         when INTER_FRAME =>

            -- apply x increment to the rocket x location
            -- clip to [0, SCREEN_WIDTH] so that the rocket doesn't go off the screen
            x_increment_var := to_integer(signed(x_increment));
            if (x_reg + x_increment_var < 0) then
               x_next <= 0;
            elsif (x_reg + x_increment_var > SCREEN_WIDTH - ROCKET_WIDTH) then
               x_next <= SCREEN_WIDTH - ROCKET_WIDTH;
            else
               x_next <= x_reg + x_increment_var;
            end if;

            draw_addr_next <= 0;
            state_next <= RENDER;

      end case;
   end process;

   color <= (others => '1');
   x_mid <= std_logic_vector(to_unsigned(x_reg + ROCKET_WIDTH/2,x_mid'length));
end rtl;
