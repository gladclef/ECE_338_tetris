library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

-- Rachel Cazzola
entity Bullet is
   Port (
      reset, clk, start, stop: in std_logic;
      frame_update: in std_logic;
      pix_en: in std_logic;
      bullet_button: in std_logic;
      x_mid_start: in std_logic_vector(SCREEN_WIDTH_NB-1 downto 0);
      pix_x: in std_logic_vector(SCREEN_WIDTH_NB-1 downto 0);
      pix_y: in std_logic_vector(SCREEN_HEIGHT_NB-1 downto 0);
      pix_bullet_en: out std_logic;
      color: out std_logic_vector(23 downto 0)
   );
end Bullet;

architecture rtl of Bullet is
   type state_type is (IDLE, ACTIVE, INTER_FRAME);
   
   signal bullet_x_reg, bullet_x_next: integer range 0 to SCREEN_WIDTH_MAX;
   signal bullet_y_reg, bullet_y_next: integer range 0 to SCREEN_HEIGHT_MAX;
   signal off_screen: std_logic;
   signal state_reg, state_next: state_type;
   signal draw_addr_reg, draw_addr_next: integer range 0 to BULLET_ADDR_MAX;
   
   begin 

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg <= IDLE;
         bullet_x_reg <= 0;
         bullet_y_reg <= BULLET_Y_START; 
         draw_addr_reg <= 0;               
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
         bullet_x_reg <= bullet_x_next;
         bullet_y_reg <= bullet_y_next;
         draw_addr_reg <= draw_addr_next;
      end if;
   end process;
   
   off_screen <= '1' when (bullet_y_reg <= BULLET_SPEED) else '0';
   color <= COLOR_PURPLE; 
   
   -- combinational circuit
   process(state_reg, reset, start, stop, pix_x, pix_y, frame_update, draw_addr_reg, bullet_x_reg, bullet_y_reg, bullet_button, x_mid_start, pix_en, off_screen)
      variable rbits: std_logic_vector(0 to BULLET_ADDR_MAX);
      variable pix_x_int: integer range -SCREEN_WIDTH_MAX to SCREEN_WIDTH_MAX;
      variable pix_y_int: integer range 0 to SCREEN_HEIGHT_MAX;
      variable y_increment_var: integer range -ROCKET_MAX_MOVE_RATE to ROCKET_MAX_MOVE_RATE; --update to y values

   begin
      state_next <= state_reg;
      bullet_x_next <= bullet_x_reg;
      bullet_y_next <= bullet_y_reg;
      draw_addr_next <= draw_addr_reg;
      pix_bullet_en <= '0';

      --use that x_mid value to set the bullet position when it gets created (aka when it goes from the idle to active states)
      case state_reg is
         when IDLE =>
            -- state logic
            if (bullet_button = '1') then
               bullet_x_next  <= to_integer(unsigned(x_mid_start)); -- x_mid_start := std_logic_vector(to_unsigned(x_reg + ROCKET_WIDTH/2,x_mid'length));
               bullet_y_next <= BULLET_Y_START;
               state_next <= ACTIVE;  
            end if;

         when ACTIVE =>
            pix_x_int := to_integer(unsigned(pix_x));
            pix_y_int := to_integer(unsigned(pix_y));

            rbits := "1" &
                     "1" &
                     "1" &
                     "1" &
                     "1" &
                     "1" &
                     "1";

            -- draw the bullet if within the borders of the current bullet position
            if (pix_en = '1') then
                if (pix_y_int >= bullet_y_reg and pix_y_int < bullet_y_reg + BULLET_HEIGHT) then
                    if (pix_x_int >= bullet_x_reg and pix_x_int < bullet_x_reg+BULLET_WIDTH) then        
                        pix_bullet_en <= rbits(draw_addr_reg);
                        --color <= COLOR_BLUE;
                        if (draw_addr_reg /= BULLET_ADDR_MAX) then
                            draw_addr_next <= draw_addr_reg + 1;
                        end if;
                    end if;
                end if;
            end if;

            if (frame_update = '1') then
               state_next <= INTER_FRAME;
            elsif (stop = '1') then
               state_next <= IDLE;
            end if;

         when INTER_FRAME =>
            -- single clock cycle frame intermission to increment the bullet_y_reg
            bullet_y_next <= bullet_y_reg - BULLET_SPEED;
            state_next <= ACTIVE;

            if (stop = '1') then
               state_next <= IDLE;
            elsif (off_screen = '1') then
               state_next <= IDLE;
            end if;      

      end case;
   end process;              
   
end rtl;