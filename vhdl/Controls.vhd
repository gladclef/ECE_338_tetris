-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Rachel Cazzola, Benjamin Bean
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

-- Ben Bean
entity Controls is
   Port (
      reset, clk:        in std_logic;
      zybo_button_left:  in std_logic;
      zybo_button_right: in std_logic;
      ctrl_buttons:      in std_logic_vector(4 downto 0);
      ctrl_horizontal:   in std_logic_vector(7 downto 0);
      active_controller: in std_logic;
      bullet_button:     in std_logic;
      x_increment:       out std_logic_vector(ROCKET_MAX_MOVE_RATE_NB downto 0); -- signed, include an extra bit for negatives
      up:                out std_logic;
      down:              out std_logic;
      left:              out std_logic;
      right:             out std_logic;
      bullet_shoot:      out std_logic
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
   signal x_reg, x_next:  integer range -ROCKET_MAX_MOVE_RATE to ROCKET_MAX_MOVE_RATE;
begin

   -- Rachel Cazzola 
   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
        x_reg <= 0;   
      elsif (rising_edge(clk)) then
        x_reg <= x_next;
      end if;
   end process;

   -- Ben Bean & Rachel Cazzola
   -- decode controller buttons
   ctrl_up     <= ctrl_buttons(3) AND active_controller;
   ctrl_down   <= ctrl_buttons(2) AND active_controller;
   ctrl_left   <= ctrl_buttons(1) AND active_controller;
   ctrl_right  <= ctrl_buttons(0) AND active_controller;
   ctrl_joysel <= ctrl_buttons(4) AND active_controller;

   -- Ben Bean
   -- interpret horizontal values
   process (ctrl_horizontal, active_controller, ctrl_hor_val)
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
        
      -- Rachel Cazzola
      if (active_controller = '0') then -- switch that controls whether we use the board or controller as our controls
         ctrl_hor_val <= 0; 
      end if;    
      
       x_next <= ctrl_hor_val;
   end process;
 
   -- Ben Bean & Rachel Cazzola
   x_increment <= std_logic_vector(to_signed(5,x_increment'length))  when (zybo_button_right = '1' or ctrl_right = '1') else
                  std_logic_vector(to_signed(-5,x_increment'length)) when (zybo_button_left = '1'  or ctrl_left = '1')  else
                  std_logic_vector(to_unsigned(x_reg, x_increment'length));

   --Ben Bean
   up    <= ctrl_up;
   down  <= ctrl_down;
   left  <= '1' when (ctrl_hor_val < 0) else
            ctrl_left or zybo_button_left;
   right <= '1' when (ctrl_hor_val > 0) else
            ctrl_right or zybo_button_right;
   bullet_shoot <= up or down or bullet_button;

end rtl;
