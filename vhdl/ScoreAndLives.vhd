-- Rachel Cazzola
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity ScoreAndLives is
   Port (
      clk, reset, start, stop, frame_update: in std_logic;
      pix_x: in std_logic_vector(10 downto 0);
      pix_y: in std_logic_vector(9 downto 0);
      life: in std_logic_vector(1 downto 0);
      ascii: in std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
      pix_lives_en : out std_logic;
      color: out std_logic_vector(23 downto 0)
   );
end ScoreAndLives;

architecture rtl of ScoreAndLives is
   type state_type is (IDLE, ASCII_START, ASCII_WAIT, DRAW, INTER_FRAME);
   signal state_reg, state_next: state_type;

   -- Ben Bean
   -- dimensions constants
   CONSTANT BORDER_SIZE   : integer := 3;
   CONSTANT SLTEXT_HEIGHT : integer := 2*TEXT_BLOCK_HEIGHT+1; -- x2 for score and lives, +1 for a pixel of spacing between the two texts
   CONSTANT FULL_HEIGHT   : integer := SLTEXT_HEIGHT+BORDER_SIZE*2; -- x2 for the top and bottom borders
   CONSTANT FULL_WIDTH    : integer := TEXT_BLOCK_WIDTH+BORDER_SIZE*2;

   -- Rachel Cazzola
   -- the current x and y locations of the block
   signal block_x_reg, block_x_next: integer range 0 to 1023;
   signal block_y_reg, block_y_next: integer range 0 to 511;
   signal off_screen: std_logic; -- TODO score and lives doesn't move, don't need to check for off_screen, remove this signal

   -- latches the characters to be drawn when start gets asserted
   signal ascii_reg, ascii_next: std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);

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
         block_y_reg <= SCREEN_HEIGHT-FULL_HEIGHT-1; -- -1 for 0 indexing of pix_y
         ascii_reg <= "000000"&"000000"& ASCII_CLN & ASCII_S & ASCII_E & ASCII_V & ASCII_I & ASCII_L;
         text_width_reg <= 0;
         
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
         block_x_reg <= block_x_next;
         block_y_reg <= block_y_next;
         ascii_reg <= ascii_next;
         text_width_reg <= text_width_next;
      end if;
   end process;

   color <= COLOR_WHITE;

   -- combinational circuit
   process(state_reg, reset, start, ascii, ascii_reg, text_count, text_ready, pix_x, pix_y, block_x_reg, block_y_reg, text_width_reg, text_pixel_mask, frame_update, stop, off_screen)
      variable pix_x_int: integer range 0 to SCREEN_WIDTH_MAX;
      variable pix_y_int: integer range 0 to SCREEN_HEIGHT_MAX;
   begin
      state_next <= state_reg;
      block_x_next <= block_x_reg;
      block_y_next <= block_y_reg;
      ascii_next <= ascii_reg;
      text_width_next <= text_width_reg;
      render_start <= '0';
      pix_lives_en <= '0';

      case state_reg is
         when IDLE =>
            if (start = '1') then
               ascii_next <= ascii;
               state_next <= ASCII_START;
            end if;

         when ASCII_START =>
            -- give the RenderText component a clock cycle to get started
            render_start <= '1';
            state_next <= ASCII_WAIT;

         when ASCII_WAIT =>
            -- busy wait for the RenderText component to finish generating their bits 
            text_width_next <= to_integer(unsigned(text_count)) * 4;
            if (text_ready = '1') then
               state_next <= DRAW;
            end if;

         when DRAW =>
            pix_x_int := to_integer(unsigned(pix_x));
            pix_y_int := to_integer(unsigned(pix_y));

            -- draw out the border as it comes up
            if (pix_y_int >= block_y_reg and pix_y_int <= block_y_reg+FULL_HEIGHT-1) then
               if (pix_x_int = block_x_reg) then                         -- left border
                  pix_lives_en <= '1';
               end if;
               if (pix_x_int = block_x_reg+text_width_reg+5-1) then      -- right border
                  pix_lives_en <= '1';
               end if;
               if (pix_x_int > block_x_reg and pix_x_int < block_x_reg+text_width_reg+5) then
                   if (pix_y_int = block_y_reg) then                     -- top border
                      pix_lives_en <= '1';
                   end if;
                   if (pix_y_int = block_y_reg+FULL_HEIGHT-1) then -- bottom border
                      pix_lives_en <= '1';
                   end if;
               end if;
            end if;

            -- draw out the text pixels
            -- checks if the pixel mask is '1' for the current pix_x and pix_y
            for row in 0 to TEXT_BLOCK_HEIGHT-1 loop
               -- draw the lives text
               if (pix_y_int = block_y_reg+BORDER_SIZE+row) then -- in the text row
                  if (pix_x_int > block_x_reg+BORDER_SIZE-1 and pix_x_int < block_x_reg+text_width_reg+(BORDER_SIZE-1)*2) then -- in the text block
                     pix_lives_en <= text_pixel_mask(TEXT_BLOCK_WIDTH*row + pix_x_int-block_x_reg-BORDER_SIZE);
                  end if;
               end if;

               -- draw the score text
               -- TODO
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
            state_next <= DRAW;

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
      start  => render_start,
      ascii  => ascii_reg,
      count  => text_count,
      pixels => text_pixel_mask,
      ready  => text_ready
   );


end rtl;
