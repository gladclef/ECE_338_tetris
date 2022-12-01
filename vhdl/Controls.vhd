-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Rachel Cazolla, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    Controls - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Manages the control logic based on button input.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--=========================================================
--
-- Manages the control logic based on user input. This includes the
-- left and right rocket speed, and the bullet firing.
--
--=========================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity Controls is
   Port (
      zybo_button_left:  in std_logic;
      zybo_button_right: in std_logic;
      ctrl_buttons:      in std_logic_vector(4 downto 0);
      ctrl_horizontal:   in std_logic_vector(7 downto 0);
      x_increment:       out std_logic_vector(ROCKET_MAX_MOVE_RATE_NB downto 0); -- signed, include an extra bit for negatives
      up:                out std_logic;
      down:              out std_logic;
      left:              out std_logic;
      right:             out std_logic
   );
end Controls;

architecture rtl of Controls is
   signal ctrl_up:        std_logic;
   signal ctrl_down:      std_logic;
   signal ctrl_left:      std_logic;
   signal ctrl_right:     std_logic;
   signal ctrl_joysel:    std_logic;
   signal ctrl_hor_val:   integer range -ROCKET_MAX_MOVE_RATE to ROCKET_MAX_MOVE_RATE;
   signal ctrl_hor_left:  std_logic;
   signal ctrl_hor_right: std_logic;
begin

   -- decode controller buttons
   ctrl_up     <= ctrl_buttons(3);
   ctrl_down   <= ctrl_buttons(2);
   ctrl_left   <= ctrl_buttons(1);
   ctrl_right  <= ctrl_buttons(0);
   ctrl_joysel <= ctrl_buttons(4);

   -- interpret horizontal values
   process (ctrl_horizontal)
      variable hor_val: signed(ROCKET_MAX_MOVE_RATE_NB downto 0);
      variable hor_ord: std_logic;
   begin
      hor_val := signed(ctrl_horizontal(7 downto 7-ROCKET_MAX_MOVE_RATE_NB));
      if (hor_val < ROCKET_MAX_MOVE_RATE) then
         if (hor_val > -ROCKET_MAX_MOVE_RATE) then
            if (hor_val = 1 or hor_val = -1) then
               ctrl_hor_val <= 0;
            else
               ctrl_hor_val <= to_integer(hor_val);
            end if;
         else
            ctrl_hor_val <= -ROCKET_MAX_MOVE_RATE;
         end if;
      else
         ctrl_hor_val <= ROCKET_MAX_MOVE_RATE;
      end if;
   end process;

   x_increment <= std_logic_vector(to_signed(2,x_increment'length))  when (zybo_button_right = '1' or ctrl_right = '1') else
                  std_logic_vector(to_signed(-2,x_increment'length)) when (zybo_button_left = '1'  or ctrl_left = '1')  else
                  ctrl_horizontal(7 downto 7-ROCKET_MAX_MOVE_RATE_NB);

   up    <= ctrl_up;
   down  <= ctrl_down;
   left  <= '1' when (ctrl_hor_val < 0) else
            ctrl_left or zybo_button_left;
   right <= '1' when (ctrl_hor_val > 0) else
            ctrl_right or zybo_button_right;

end rtl;
