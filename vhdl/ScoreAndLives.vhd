library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

-- Rachel Cazzola
entity ScoreAndLives is
   Port (
      clk, reset, start, stop, frame_update: in std_logic;
      pix_x: in std_logic_vector(10 downto 0);
      pix_y: in std_logic_vector(9 downto 0);
      life: in std_logic_vector(1 downto 0);
      score_digit0, score_digit1 : in std_logic_vector(5 downto 0);
      pix_LivesScore_en : out std_logic;
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
   signal lives_reg, lives_next: std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0); -- latches the characters to be drawn when start gets asserted
   signal score_reg, score_next: std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);

   -- signals to and from the RenderText module  
   signal lives_render_start, score_render_start: std_logic; -- starts the RenderText module
   signal lives_text_ready, score_text_ready: std_logic; -- when the RenderText module is done rendering
   signal lives_text_pixel_mask, score_text_pixel_mask: std_logic_vector(0 to TEXT_BLOCK_ADDR-1); -- the pixels rendered to by RenderText, to be drawn to the screen
   signal lives_text_width_reg, lives_text_width_next, score_text_width_reg, score_text_width_next: integer range 0 to 1023; -- the number of bits that are occupied on the screen by the rendered text
   signal lives_text_count, score_text_count: std_logic_vector(MATH_BLOCK_MAX_CHARS_NB-1 downto 0); -- a count of how many characters are in the lives_reg
   
begin 

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg <= IDLE;
         block_x_reg <= 0;
         block_y_reg <= SCREEN_HEIGHT-FULL_HEIGHT-1; -- -1 for 0 indexing of pix_y
         lives_reg <= "000000"&"000000" & ASCII_CLN & ASCII_S & ASCII_E & ASCII_V & ASCII_I & ASCII_L;
         lives_text_width_reg <= 0;
         score_reg <= score_digit1 & score_digit0 & ASCII_CLN & ASCII_E & ASCII_R & ASCII_O & ASCII_C & ASCII_S; 
         score_text_width_reg <= 0;
         
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
         block_x_reg <= block_x_next;
         block_y_reg <= block_y_next;
         lives_reg <= lives_next;
         score_reg <= score_next;
         lives_text_width_reg <= lives_text_width_next;
         score_text_width_reg <= score_text_width_next;
      end if;
   end process;

   color <= COLOR_WHITE;

   -- combinational circuit
   process(state_reg, reset, start, lives_reg, score_reg, lives_text_count, score_text_count, lives_text_ready, score_text_ready, pix_x, pix_y, block_x_reg, block_y_reg, lives_text_width_reg, score_text_width_reg, lives_text_pixel_mask, score_text_pixel_mask, frame_update, stop, score_digit0, score_digit1)
      variable pix_x_int: integer range 0 to SCREEN_WIDTH_MAX;
      variable pix_y_int: integer range 0 to SCREEN_HEIGHT_MAX;
   begin
      state_next <= state_reg;
      block_x_next <= block_x_reg;
      block_y_next <= block_y_reg;
      lives_next <= lives_reg;
      score_next <= score_reg;
      lives_text_width_next <= lives_text_width_reg;
      score_text_width_next <= score_text_width_reg;
      lives_render_start <= '0';
      score_render_start <= '0';
      pix_LivesScore_en <= '0';
           
      case state_reg is
         when IDLE =>
            if (start = '1') then
               state_next <= ASCII_START;
            end if;

         when ASCII_START =>
            -- give the RenderText component a clock cycle to get started
            lives_render_start <= '1';
            score_render_start <= '1';
            state_next <= ASCII_WAIT;

         when ASCII_WAIT =>
            -- busy wait for the RenderText component to finish generating their bits           
            lives_text_width_next <= to_integer(unsigned(lives_text_count)) * 4;
            score_text_width_next <= to_integer(unsigned(score_text_count)) * 4;
            if (lives_text_ready = '1' and score_text_ready = '1') then
                state_next <= DRAW;
            end if;

         when DRAW =>
            pix_x_int := to_integer(unsigned(pix_x));
            pix_y_int := to_integer(unsigned(pix_y));

            -- draw out the border as it comes up
            if (pix_y_int >= block_y_reg and pix_y_int <= block_y_reg+FULL_HEIGHT-1) then
               if (pix_x_int = block_x_reg) then                         -- left border
                  pix_LivesScore_en <= '1';
               end if;
               if (pix_x_int = block_x_reg + lives_text_width_reg+5-1) then      -- right border
                  pix_LivesScore_en <= '1';
               end if;
               if (pix_x_int > block_x_reg and pix_x_int < block_x_reg + lives_text_width_reg+5) then
                   if (pix_y_int = block_y_reg) then                     -- top border
                      pix_LivesScore_en <= '1';
                   end if;
                   if (pix_y_int = block_y_reg+FULL_HEIGHT-1) then -- bottom border
                      pix_LivesScore_en <= '1';
                   end if;
               end if;                              
            end if;

            -- draw out the text pixels
            -- checks if the pixel mask is '1' for the current pix_x and pix_y
            for row in 0 to TEXT_BLOCK_HEIGHT-1 loop
               -- draw the lives text
               if (pix_y_int = block_y_reg+BORDER_SIZE+row) then -- in the text row
                  if (pix_x_int > block_x_reg+BORDER_SIZE-1 and pix_x_int < block_x_reg+lives_text_width_reg+(BORDER_SIZE-1)*2) then  -- in the text block
                     pix_LivesScore_en <= lives_text_pixel_mask(TEXT_BLOCK_WIDTH*row + pix_x_int-block_x_reg-BORDER_SIZE);
                  end if;
               end if;

               -- draw the score text
               if (pix_y_int = block_y_reg+8+BORDER_SIZE+row) then -- in the text row
                  if (pix_x_int > block_x_reg+BORDER_SIZE-1 and pix_x_int < block_x_reg+score_text_width_reg+(BORDER_SIZE-1)*2) then  -- in the text block
                     pix_LivesScore_en <= score_text_pixel_mask(TEXT_BLOCK_WIDTH*row + pix_x_int-block_x_reg-BORDER_SIZE);
                  end if;
               end if;
               
            end loop;

            if (frame_update = '1') then
               state_next <= INTER_FRAME;
            elsif (stop = '1') then
               state_next <= IDLE;
            end if;

         when INTER_FRAME =>
            -- single clock cycle frame intermission to increment the block_y_reg
            state_next <= DRAW;

            if (stop = '1') then
               state_next <= IDLE;
            end if;

      end case;
   end process;

   render_text: entity work.RenderText(rtl)
   port map (
      reset  => reset,
      clk    => clk,
      start  => lives_render_start,
      ascii  => lives_reg,
      count  => lives_text_count,
      pixels => lives_text_pixel_mask,
      ready  => lives_text_ready
   );
   
   render_text2: entity work.RenderText(rtl)
   port map (
      reset  => reset,
      clk    => clk,
      start  => score_render_start,
      ascii  => score_reg,
      count  => score_text_count,
      pixels => score_text_pixel_mask,
      ready  => score_text_ready
   );

end rtl;
