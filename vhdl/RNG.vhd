-- Ben Bean
-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Benjamin Bean, Rachel Cazzola
-- 
-- Module Name:    RNG - behavioral
-- Description:    Generates random numbers by compiling several random and
--                 pseudorandom sources.
--
-----------------------------------------------------------
-- FSM created with https://github.com/gladclef/FSMs
-- {'fsm_name': 'RNG', 'table_vals': [['', 'locked', 'start', ''], ['WAIT_LOCK', 'IDLE', '', ''], ['IDLE', '', 'READY', ''], ['READY', '', '', '']]}
-----------------------------------------------------------

-- RNG generates random number values

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity RNG is
   Port (
      -- standard signals
      clk:            in std_logic;
      reset:          in std_logic;

      -- use delayed locking in the PLLs as an initial source of randomness
      -- use the pclk (processor clock) to count on the seed while waiting for the rclk clock to lock
      pclk:           in std_logic;
      rclk_locked:    in std_logic;
      rclk_resetn:    out std_logic;

      -- game start
      start:          in std_logic;

      -- use user input as a true source of randomness
      zybo_btn_left:  in std_logic;
      zybo_btn_right: in std_logic;
      ctrl_btns:      in std_logic_vector(4 downto 0);

      -- get the next random value every time this is asserted
      read:           in std_logic;

      -- output random + pseudorandom value
      randval:        out std_logic_vector(10 downto 0);
      seed:           out std_logic_vector(10 downto 0)
   );
end RNG;

architecture rtl of RNG is
   type state_type is (WAIT_LOCK, IDLE, READY);
   signal state_reg, state_next: state_type;

   -- LFSR signals
   signal lfsr_seed_reg, lfsr_seed_next: integer range 2**seed'length-1 downto 0;
   signal lfsr_seed:      std_logic_vector(10 downto 0);
   signal lfsr_load_seed: std_logic;
   signal lfsr_start:     std_logic;
   signal lfsr_randval:   std_logic_vector(10 downto 0);

   -- TRNG signals
   signal trng_newval:         std_logic;                     -- goes high for one clock cycle when there is a new trng_val
   signal trng_val:            std_logic_vector(10 downto 0); -- a truly random value
   signal trng_load_reg, trng_load_next: std_logic;           -- the latched version of trnv_newval
begin

   -- for the initial state, when we're waiting for a lock from the random clocks
   process(pclk)
   begin
      if (rising_edge(pclk)) then
         lfsr_seed_reg  <= lfsr_seed_next;
      end if;
   end process;

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg     <= WAIT_LOCK;
         trng_load_reg <= '0';
      elsif (rising_edge(clk)) then
         state_reg     <= state_next;
         trng_load_reg <= trng_load_next;
      end if;
   end process;

   -- combinational circuit
   process(state_reg, start, lfsr_randval, lfsr_seed_reg, rclk_locked, read, trng_load_reg, trng_val, trng_newval)
      variable slv: std_logic_vector(10 downto 0);
   begin
      state_next     <= state_reg;
      lfsr_seed_next <= lfsr_seed_reg;
      
      lfsr_load_seed <= '0';
      lfsr_start     <= '0';
      trng_load_next <= '0';

      case state_reg is
         when WAIT_LOCK =>
            lfsr_seed_next <= lfsr_seed_reg + 1;

            if (rclk_locked = '1') then
               state_next <= IDLE;
               lfsr_start <= '1';
               lfsr_load_seed <= '1';
            end if;

         when IDLE =>
            lfsr_start <= '1';

            if (start = '1') then
               state_next <= READY;
            end if;

         when READY =>
            -- Every time we have a new truly random value, add it to
            -- the current random value and start generating at a fresh
            -- location by reseeding the LFSR.
            -- Take an extra clock cycle to do this to relieve some
            -- of the timing constraints of the logic, which is kind of
            -- already a lot between the xor and the load_seed.
            if (trng_newval = '1') then
               for i in 0 to 10 loop
                   slv(i) := trng_val(i) xor lfsr_randval(i);
               end loop;
               lfsr_seed_next <= to_integer(unsigned(slv));
               trng_load_next <= '1';
            end if;
            if (trng_load_reg = '1') then
               lfsr_load_seed <= '1';
               lfsr_start     <= '1';
            end if;

            -- every time a value is read, generate the next LFSR value
            if (read = '1') then
               lfsr_start <= '1';
            end if;

         when others =>
            lfsr_seed_next <= lfsr_seed_reg + 1;

      end case;
   end process;

   lfsr: entity work.LFSR(rtl)
   port map(
      reset     => reset,          -- in
      clk       => clk,            -- in
      start     => lfsr_start,     -- in
      load_seed => lfsr_load_seed, -- in
      seed      => lfsr_seed,      -- in
      retval    => lfsr_randval    -- out
   );
   lfsr_seed <= std_logic_vector(to_unsigned(lfsr_seed_reg,lfsr_seed'length));
   seed      <= std_logic_vector(to_unsigned(lfsr_seed_reg,lfsr_seed'length));
   randval   <= lfsr_randval;

   trng: entity work.TRNG(rtl)
   port map(
      -- standard values
      clk         => clk,         -- in

      -- rclk values
      rclk_locked => rclk_locked, -- in
      rclk_resetn => rclk_resetn, -- out

      -- results
      new_rval    => trng_newval, -- out
      rval        => trng_val     -- out
   );

end rtl;
