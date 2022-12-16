-- Ben Bean
-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Benjamin Bean, Rachel Cazzola
-- 
-- Module Name:    MasterMathBlock - behavioral
-- Description:    Manages the creation of math blocks.
--                 
--                 Math blocks are created randomly and with random equations, with some requirements:
--                  * min 10 frames between new MBs
--                  * max 4 secs between new MBs
--                  * max 4 MBs on screen at a time
--                  * numbers must be positive and 1 to 2 digits
--                  * no more than 3 correct or incorrect MBs in a row
--
-----------------------------------------------------------
-- FSM created with https://github.com/gladclef/FSMs
-- {"fsm_name":"MasterMathBlock","table_vals":[["","create_new","__","done_counting"],["IDLE","GEN_FIRST","",""],["GEN_FIRST","","GEN_SECOND",""],["GEN_SECOND","","GEN_OP",""],["GEN_OP","","GEN_RESULT",""],["GEN_RESULT","","GEN_INCORRECT",""],["GEN_INCORRECT","","GEN_ASCII",""],["GEN_ASCII","","ACTIVATE_BLOCK",""],["ACTIVATE_BLOCK","","COUNT_ACTIVE",""],["COUNT_ACTIVE","","","IDLE"]]}
-----------------------------------------------------------

-- MasterMathBlock manages the creation of math blocks.

-- Rachel Cazzola
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity MasterMathBlock is
   Port (
      -- standard signals
      reset:        in std_logic;
      clk:          in std_logic;
      start:        in std_logic;
      stop:         in std_logic;
      ready:        out std_logic;

      -- fall rate of the math blocks
      y_increment:  in std_logic_vector(MAX_FALL_RATE_NB-1 downto 0);

      -- random values
      randval:      in std_logic_vector(10 downto 0);
      read_rand:    out std_logic;

      -- pixel value currently being drawn
      pix_x:        in std_logic_vector(SCREEN_WIDTH_NB-1 downto 0);
      pix_y:        in std_logic_vector(SCREEN_HEIGHT_NB-1 downto 0);

      -- the one cycle frame sync at the end of every frame
      frame_update: in std_logic;

      -- is pix_x/pix_y a math block pixel? if so, what color should be drawn?
      pix_en:       out std_logic;
      color:        out std_logic_vector(23 downto 0);
      
      -- Ben Bean
      -- collison, score, and lives
      rocket_mid_x:   in  std_logic_vector(SCREEN_WIDTH_NB-1 downto 0);
      bullet_x:       in  std_logic_vector(SCREEN_WIDTH_NB-1 downto 0);
      bullet_y:       in  std_logic_vector(SCREEN_HEIGHT_NB-1 downto 0);
      bullet_active:  in  std_logic;
      score_increase: out std_logic;
      life_decrease:  out std_logic
      
      -- Rachel Cazzola
   );
end MasterMathBlock;

architecture rtl of MasterMathBlock is
   type state_type is (IDLE, CHECK_COLLISION, COUNT_ACTIVE, GEN_FIRST, GEN_SECOND, GEN_OP, GEN_RESULT, GEN_INCORRECT, GEN_ASCII, ACTIVATE_BLOCK);
   signal state_reg, state_next: state_type;

   -- Arrays of values, one value per math block
   constant NUM_MB : integer := 4;
   type std_logic_array  is array(0 to NUM_MB-1) of std_logic;
   type vectorX_Array    is array(0 to NUM_MB-1) of std_logic_vector(SCREEN_WIDTH_NB-1 downto 0);
   type vectorAsciiArray is array(0 to NUM_MB-1) of std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
   type vectorPosArray   is array(0 to NUM_MB-1) of std_logic_vector(SCREEN_HEIGHT_NB-1 downto 0);
   type vectorColorArray is array(0 to NUM_MB-1) of std_logic_vector(23 downto 0);
   
   signal readys : std_logic_array;
   signal starts_reg, starts_next : std_logic_array;
   signal stops_reg, stops_next : std_logic_array;
   signal xs_reg, xs_next : vectorX_Array;
   signal asciis_reg, asciis_next : vectorAsciiArray;
   signal y_poss: vectorPosArray;
   signal widths: vectorX_Array;
   signal pix_ens : std_logic_array;
   signal colors : vectorColorArray;
   signal set_correct_reg, set_correct_next : std_logic_array;
   signal get_correct : std_logic_array;

   -- Ben Bean
   -- MG generation requirements
   constant MIN_INTER_FRAMES : integer := 10;
   constant MAX_INTER_FRAMES : integer := 4*60;
   signal n_interframes_reg, n_interframes_next: integer range 0 to 480; -- number of frames since the last math block has been drawn
   signal n_correct_reg, n_correct_next:         integer range 0 to 3; -- number of correct equations in a row
   signal n_incorrect_reg, n_incorrect_next:     integer range 0 to 3; -- number of incorrect equations in a row

   -- equation pieces
   type op_type is (ADD, SUBTRACT, MULTIPLY, DIVIDE);
   signal gen_first_reg, gen_first_next:     std_logic_vector(6 downto 0);
   signal gen_second_reg, gen_second_next:   std_logic_vector(6 downto 0);
   signal gen_op_reg, gen_op_next:           op_type;
   signal gen_result_reg, gen_result_next:   std_logic_vector(6 downto 0);
   signal gen_num_reg, gen_num_next:         integer range 0 to 99;
   signal gen_ascii_reg, gen_ascii_next:     std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);

   -- find the next ready math block, so that we know if any can be recycled for "creation"
   signal first_ready_reg, first_ready_next: integer range 0 to NUM_MB;

   -- counter, used in several states
   signal i_reg, i_next:                     integer range 0 to 8; --maximum(NUM_MB, MATH_BLOCK_MAX_CHARS);

begin

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg         <= IDLE;
         for i in 0 to NUM_MB-1 loop
            starts_reg(i)  <= '0';
            stops_reg(i)   <= '0';
            xs_reg(i)      <= (others => '0');
            asciis_reg(i)  <= (others => '0');
            set_correct_reg(i) <= '0';
         end loop;
         n_interframes_reg <= 0;
         n_correct_reg     <= 0;
         n_incorrect_reg   <= 0;
         gen_first_reg     <= (others => '0');
         gen_second_reg    <= (others => '0');
         gen_op_reg        <= ADD;
         gen_result_reg    <= (others => '0');
         gen_num_reg       <= 0;
         gen_ascii_reg     <= (others => '0');
         first_ready_reg   <= 0;
         i_reg             <= 0;
      elsif (rising_edge(clk)) then
         state_reg         <= state_next;
         for i in 0 to NUM_MB-1 loop
            starts_reg(i)  <= starts_next(i);
            stops_reg(i)   <= stops_next(i);
            xs_reg(i)      <= xs_next(i);
            asciis_reg(i)  <= asciis_next(i);
            set_correct_reg(i) <= set_correct_next(i);
         end loop;
         n_interframes_reg <= n_interframes_next;
         n_correct_reg     <= n_correct_next;
         n_incorrect_reg   <= n_incorrect_next;
         gen_first_reg     <= gen_first_next;
         gen_second_reg    <= gen_second_next;
         gen_op_reg        <= gen_op_next;
         gen_result_reg    <= gen_result_next;
         gen_num_reg       <= gen_num_next;
         gen_ascii_reg     <= gen_ascii_next;
         first_ready_reg   <= first_ready_next;
         i_reg             <= i_next;
      end if;
   end process;

   -- combinational circuit
   process(state_reg, starts_reg, stops_reg, xs_reg, asciis_reg, y_poss, widths, get_correct, set_correct_reg, pix_y, frame_update, rocket_mid_x, bullet_x, bullet_y, bullet_active, n_interframes_reg, n_correct_reg, n_incorrect_reg, gen_first_reg, gen_second_reg, gen_op_reg, gen_result_reg, gen_num_reg, gen_ascii_reg, first_ready_reg, i_reg, randval, readys)
      variable create_new : std_logic;
      variable create_correct : std_logic;
      variable rand_t3  : std_logic_vector(1 downto 0);
      variable rand_127 : std_logic_vector(6 downto 0);
      variable rand_511 : std_logic_vector(8 downto 0);
      variable int_rand_511 : integer range 0 to 511;
      variable v  : integer range 0 to 99;
      variable v1 : integer range 0 to 99;
      variable v2 : integer range 0 to 99;
      variable vr : integer range 0 to 99;
      variable randop : op_type;
      variable a1 : std_logic_vector(ASCII_NB-1 downto 0);
      variable a2 : std_logic_vector(ASCII_NB-1 downto 0);
      variable int_x:        integer range 0 to SCREEN_WIDTH_MAX-1;
      variable int_width:    integer range 0 to SCREEN_WIDTH_MAX-1;
      variable int_y:        integer range 0 to SCREEN_HEIGHT_MAX-1;
      variable int_rocket_x: integer range 0 to SCREEN_WIDTH_MAX-1;
      variable int_bullet_x: integer range 0 to SCREEN_WIDTH_MAX-1;
      variable int_bullet_y: integer range 0 to SCREEN_HEIGHT_MAX-1;
   begin
      state_next         <= state_reg;
      for i in 0 to NUM_MB-1 loop
         starts_next(i)  <= starts_reg(i);
         stops_next(i)   <= stops_reg(i);
         xs_next(i)      <= xs_reg(i);
         asciis_next(i)  <= asciis_reg(i);
         set_correct_next(i) <= set_correct_reg(i);
      end loop;
      n_interframes_next <= n_interframes_reg;
      n_correct_next     <= n_correct_reg;
      n_incorrect_next   <= n_incorrect_reg;
      gen_first_next     <= gen_first_reg;
      gen_second_next    <= gen_second_reg;
      gen_op_next        <= gen_op_reg;
      gen_result_next    <= gen_result_reg;
      gen_num_next       <= gen_num_reg;
      gen_ascii_next     <= gen_ascii_reg;
      first_ready_next   <= first_ready_reg;
      i_next             <= i_reg;

      read_rand <= '0';

      rand_127 := randval(6 downto 0);
      rand_511 := randval(8 downto 0);
      int_rand_511 := to_integer(unsigned(rand_511));

      score_increase <= '0';
      life_decrease  <= '0';

      case state_reg is
         when IDLE =>
            if (frame_update = '1') then
               create_new := '0';

               -- Deassert start for all math blocks.
               -- If we don't do this, then the math blocks will loop forever
               -- between IDLE and DRAW once they are offscreen.
               for i in 0 to NUM_MB-1 loop
                  starts_next(i) <= '0';
               end loop;

               -- determine if we should create a new math block
               if (n_interframes_reg < MIN_INTER_FRAMES) then
                  -- can't create a new math block
               elsif (n_interframes_reg > MAX_INTER_FRAMES) then
                  -- must create a new math block
                  create_new := '1';
               else
                  -- create a new math block on a random time interval
                  read_rand <= '1';
                  if (int_rand_511 mod 120 = 0) then -- average 2 seconds at 60 fps
                     create_new := '1';
                  end if;
               end if;

               -- Every clock cycle do something. If not (A) then (B).
               --   (A) create a new math block
               --   (B) check for a collision
               if (create_new = '1') then
                  -- get ready for the next state
                  i_next <= 0;
                  first_ready_next <= NUM_MB;
                  
                  -- (A) go check if we have math blocks available
                  state_next <= COUNT_ACTIVE;
               else
                  n_interframes_next <= n_interframes_reg + 1;

                  -- (B) go check for a collision
                  state_next <= CHECK_COLLISION;
               end if;
            end if;

         when CHECK_COLLISION =>
            score_increase <= '0';
            life_decrease  <= '0';

            for i in 0 to NUM_MB-1 loop
               int_x        := to_integer(unsigned(xs_reg(i)));
               int_y        := to_integer(unsigned(y_poss(i)));
               int_width    := to_integer(unsigned(widths(i)));
               int_rocket_x := to_integer(unsigned(rocket_mid_x));
               int_bullet_x := to_integer(unsigned(bullet_x));

               -- check for a player collision
               if (int_y >= SCREEN_HEIGHT - ROCKET_HEIGHT - MATH_BLOCK_HEIGHT + 1 and
                     int_x <= int_rocket_x + ROCKET_WIDTH / 2 - 1 and
                     int_x >= int_rocket_x - ROCKET_WIDTH / 2 - int_width + 1) then

                  stops_next(i) <= '1';
                  if (get_correct(i) = '0') then
                     score_increase <= '1';
                  else
                     life_decrease <= '1';
                  end if;
               end if;

               -- check for a bullet collision
               if (bullet_active = '1') then
                  for p in 0 to 1 loop
                     -- check for collision at the top and bottom of the bullet
                     int_bullet_y := to_integer(unsigned(bullet_y));
                     if p = 1 then
                        int_bullet_y := int_bullet_y + BULLET_HEIGHT;
                     end if;

                     if (int_y <= int_bullet_y and
                           int_y + MATH_BLOCK_HEIGHT >= int_bullet_y and
                           int_x <= int_bullet_x and
                           int_x + int_width >= int_bullet_x) then

                        stops_next(i) <= '1';
                        if (get_correct(i) = '0') then
                           life_decrease <= '1';
                        else
                           score_increase <= '1';
                        end if;
                     end if;
                  end loop; -- top and bottom
               end if; -- bullet_active

            end loop;

         when COUNT_ACTIVE =>
            if (i_reg < NUM_MB) then
               -- count MB(i) as active if ready
               i_next <= i_reg + 1;
               if readys(i_reg) = '1' then
                  first_ready_next <= i_reg;
                  i_next <= NUM_MB;
               end if;

            -- Done counting? Then either create the next math block if one is available,
            -- or else go back to IDLE to wait for a math block to become available.
            else --if (i_reg = NUM_MB) then
               i_next <= 0;
               if (first_ready_reg /= NUM_MB) then
                  -- there's a ready math block available! use it!
                  state_next <= GEN_FIRST;
               else
                  -- no math blocks available, can't create a new math block
                  state_next <= IDLE;
               end if;
            end if;

         when GEN_FIRST =>
            -- determine first number value
            v1 := to_integer(unsigned(rand_127));
            gen_first_next <= std_logic_vector(to_unsigned( v1 mod 100, gen_first_reg'length));
            --gen_first_next <= std_logic_vector(to_unsigned( 13, gen_first_reg'length )); -- testing

            read_rand <= '1';
            state_next <= GEN_SECOND;

         when GEN_SECOND =>
            -- determine second number value
            v1 := to_integer(unsigned(rand_127));
            gen_second_next <= std_logic_vector(to_unsigned( v1 mod 100, gen_first_reg'length));
            --gen_second_next <= std_logic_vector(to_unsigned( 24, gen_first_reg'length )); -- testing

            read_rand <= '1';
            state_next <= GEN_OP;

         when GEN_OP =>
            -- determine the operation type (+-/*)
            randop := DIVIDE;
            if (randval(10 downto 9) = "00") then
                randop := ADD;
            elsif (randval(10 downto 9) = "01") then
                randop := SUBTRACT;
            elsif (randval(10 downto 9) = "10") then
                randop := MULTIPLY;
            end if;
            --randop := ADD; -- testing
            gen_op_next <= randop;
            
            -- update first and second number values based on the op type
            v1 := to_integer(unsigned(gen_first_reg));
            v2 := to_integer(unsigned(gen_second_reg));
            if randop = DIVIDE or randop = MULTIPLY then
               gen_second_next <= std_logic_vector(to_unsigned(v2 mod 15, gen_first_reg'length));    -- limit 2nd to 14
               if gen_second_reg(3 downto 2) = "11" then                                             --   if 2nd >= 12, "xx11xx"
                  gen_first_next <= gen_first_reg and "0000111";                                     --     limit 3rd to 0-7
               elsif gen_second_reg(3 downto 2) = "10" then                                          --   if 2nd >= 8, "xx10xx"
                  gen_first_next <= std_logic_vector(to_unsigned( v1 mod 10, gen_first_reg'length)); --     limit 3rd to 9
               else                                                                                  --   if 2nd < 8, "xx100x"
                  gen_first_next <= std_logic_vector(to_unsigned(v1 mod 15, gen_first_reg'length));  --     limit 3rd to 14
               end if;
            else -- SUBTRACTION or ADDITION
               gen_first_next  <= std_logic_vector(to_unsigned( v1 mod 51, gen_first_reg'length));
               gen_second_next <= std_logic_vector(to_unsigned( v2 mod 51, gen_first_reg'length));
            end if;

            read_rand <= '1';
            state_next <= GEN_RESULT;

         when GEN_RESULT =>
            -- determine the result number value
            v1 := to_integer(unsigned(gen_first_reg));
            v2 := to_integer(unsigned(gen_second_reg));
            vr := to_integer(unsigned(gen_result_reg));

            if gen_op_reg = DIVIDE then
               -- 1st and 2nd set up so that they can be multiplied to a value <= 100
               v  := v1 * v2;
               vr := v1;
               v1 := v;
            elsif gen_op_reg = MULTIPLY then
               -- 1st and 2nd set up so that they can be multiplied to a value <= 100
               vr := v1 * v2;
            elsif gen_op_reg = SUBTRACT then
               -- 1nd and 2nd are both <= 50
               v  := v1 + v2;
               vr := v1;
               v1 := v;
            elsif gen_op_reg = ADD then
               -- 1nd and 2nd are both <= 50
               vr := v1 + v2;
            end if;
            --vr := 37; -- testing

            gen_first_next  <= std_logic_vector(to_unsigned(v1, gen_first_reg'length));
            gen_second_next <= std_logic_vector(to_unsigned(v2, gen_first_reg'length));
            gen_result_next <= std_logic_vector(to_unsigned(vr, gen_first_reg'length));

            state_next <= GEN_INCORRECT;

         when GEN_INCORRECT =>
            -- determine correctness
            if (n_correct_reg = 3) then
               create_correct := '0';
            elsif (n_incorrect_reg = 3) then
               create_correct := '1';
            else
               create_correct := randval(10);
            end if;
            set_correct_next(first_ready_reg) <= create_correct;
            --set_correct_next(0) <= create_correct; -- testing

            -- count correct/incorrect
            if create_correct = '0' then
               n_correct_next <= 0;
               n_incorrect_next <= n_incorrect_reg + 1;
            else
               n_correct_next <= n_correct_reg + 1;
               n_incorrect_next <= 0;
            end if;

            -- adjust values
            if create_correct = '0' then
               vr := to_integer(unsigned(gen_result_reg and "1111000"));
               if (vr < 86) then
                  v  := to_integer(unsigned(rand_127)) mod 14;
                  if v = 7 then
                     v := 6;
                  end if;
                  vr := vr + v;
               end if;
               --vr := 48; -- testing
               gen_result_next <= std_logic_vector(to_unsigned(vr, gen_first_reg'length));
            end if;

            -- get ready for the next state
            v1 := to_integer(unsigned(gen_first_reg));
            i_next <= 0;
            gen_num_next <= v1 mod 10;

            state_next <= GEN_ASCII;

         when GEN_ASCII =>
            v1 := to_integer(unsigned(gen_first_reg));
            v2 := to_integer(unsigned(gen_second_reg));
            vr := to_integer(unsigned(gen_result_reg));

            -- generate the next character
            if (i_reg = 0 or i_reg = 3 or i_reg = 6) then
               -- generate the ten's place
               v := vr;
               if (i_reg = 0) then
                  v := v1;
               elsif (i_reg = 3) then
                  v := v2;
               end if;
               a1 := ascii_9;
               if (v < 10) then
                  a1 := ASCII_0;
               elsif (v < 20) then
                  a1 := ASCII_1;
               elsif (v < 30) then
                  a1 := ASCII_2;
               elsif (v < 40) then
                  a1 := ASCII_3;
               elsif (v < 50) then
                  a1 := ASCII_4;
               elsif (v < 60) then
                  a1 := ASCII_5;
               elsif (v < 70) then
                  a1 := ASCII_6;
               elsif (v < 80) then
                  a1 := ASCII_7;
               elsif (v < 90) then
                  a1 := ASCII_8;
               end if;
               gen_ascii_next((i_reg+1)*ASCII_NB-1 downto (i_reg+0)*ASCII_NB) <= a1;
               
               -- generate the one's place
               a2 := ascii_9;
               if (gen_num_reg = 0) then
                  a2 := ASCII_0;
               elsif (gen_num_reg = 1) then
                  a2 := ASCII_1;
               elsif (gen_num_reg = 2) then
                  a2 := ASCII_2;
               elsif (gen_num_reg = 3) then
                  a2 := ASCII_3;
               elsif (gen_num_reg = 4) then
                  a2 := ASCII_4;
               elsif (gen_num_reg = 5) then
                  a2 := ASCII_5;
               elsif (gen_num_reg = 6) then
                  a2 := ASCII_6;
               elsif (gen_num_reg = 7) then
                  a2 := ASCII_7;
               elsif (gen_num_reg = 8) then
                  a2 := ASCII_8;
               end if;
               gen_ascii_next((i_reg+2)*ASCII_NB-1 downto (i_reg+1)*ASCII_NB) <= a2;
               
               -- get ready for the next number
               if i_reg = 0 then
                  gen_num_next <= v2 mod 10;
               elsif i_reg = 3 then
                  gen_num_next <= vr mod 10;
               end if;

               i_next <= i_reg + 2;
               
            elsif (i_reg = 2) then
               -- generate the operation symbol
               a1 := ASCII_DIV;
               if (gen_op_reg = ADD) then
                  a1 := ASCII_PLU;
               elsif (gen_op_reg = SUBTRACT) then
                  a1 := ASCII_MIN;
               elsif (gen_op_reg = MULTIPLY) then
                  a1 := ASCII_MUL;
               end if;
               gen_ascii_next((i_reg+1)*ASCII_NB-1 downto i_reg*ASCII_NB) <= a1;

               i_next <= i_reg + 1;
               
            else -- i_reg = 5
               -- generate the equals sign
               a1 := ASCII_EQU;
               gen_ascii_next((i_reg+1)*ASCII_NB-1 downto i_reg*ASCII_NB) <= a1;

               i_next <= i_reg + 1;
               
            end if;

            if (i_reg = 6) then
               state_next <= ACTIVATE_BLOCK;
            end if;

         when ACTIVATE_BLOCK =>
            -- set up and enable the block
            starts_next(first_ready_reg) <= '1';
            stops_next(first_ready_reg)  <= '0';
            xs_next(first_ready_reg)     <= std_logic_vector(to_unsigned(   to_integer(unsigned(rand_511)) + (SCREEN_WIDTH - 512 - MATH_BLOCK_MAX_WIDTH/2),   11));
            asciis_next(first_ready_reg) <= gen_ascii_reg;

            -- register that we just created a new math block
            n_interframes_next <= 0;

            state_next <= IDLE;

      end case;

      --starts_next(0) <= '1';
      --asciis_next(0) <= "000000"&"000000"& ASCII_CLN & ASCII_S & ASCII_E & ASCII_V & ASCII_I & ASCII_L; -- gen_ascii_reg;
   end process;

   --dbg(3 downto 0) <= "0000" when state_reg = IDLE else
   --                   "0001" when state_reg = GEN_FIRST else
   --                   "0010" when state_reg = GEN_SECOND else
   --                   "0011" when state_reg = GEN_OP else
   --                   "0100" when state_reg = GEN_RESULT else
   --                   "0101" when state_reg = GEN_INCORRECT else
   --                   "0110" when state_reg = GEN_ASCII else
   --                   "0111" when state_reg = ACTIVATE_BLOCK else
   --                   "1000" when state_reg = COUNT_ACTIVE else
   --                   "1111";
   --dbg(4) <= frame_update;

   -- Rachel Cazzola
   --creating a for generate loop to generate 4 math blocks
   for_generate_math_block: for i in 0 to NUM_MB-1 generate
      MathBlock: entity work.MathBlock(rtl)
      port map (
         -- standard signals
         reset        => reset,         -- in
         clk          => clk,           -- in
         start        => starts_reg(i), -- in
         stop         => stops_reg(i),  -- in
         ready        => readys(i),     -- out

         -- correctness
         correctness  => set_correct_reg(i), -- in
         is_correct   => get_correct(i),     -- out

         -- where to place the block, and what it should display
         --x            => (others => '0'), -- in
         x            => xs_reg(i),     -- in
         ascii        => asciis_reg(i), -- in

         -- vertical speed of the block
         y_increment  => y_increment,   -- in
         y_pos        => y_poss(i),     -- out
         draw_width   => widths(i),     -- out

         -- the pixel that is currently being rendered
         pix_x        => pix_x,         -- in
         pix_y        => pix_y,         -- in

         -- math block draw enable for the given pix_x/pix_y, and the color for that pixel
         pix_mb_en    => pix_ens(i),    -- out
         color        => colors(i),     -- out

         -- the one cycle frame sync at the end of every frame
         frame_update => frame_update   -- in
      );
   end generate for_generate_math_block;
   
   -- Process drawing for each MB
   process(pix_ens, colors)
      variable pix_en_any : std_logic;
      variable var_color  : std_logic_vector(23 downto 0);
   begin
      -- set pix_en if any of the math blocks have pix_en
      pix_en_any := '0';
      var_color  := COLOR_WHITE;
      
      for i in 0 to NUM_MB-1 loop
         pix_en_any := pix_ens(i) or pix_en_any;
         if pix_ens(i) = '1' then
            var_color := colors(i);
         end if;
      end loop;

      pix_en <= pix_en_any;
      color  <= var_color;
        
   end process;
   
end rtl;