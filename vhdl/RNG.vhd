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
-- {'fsm_name': 'RNG', 'table_vals': [['', 'locked', 'start', ''], ['RCLK', 'IDLE', '', ''], ['IDLE', '', 'READY', ''], ['READY', '', '', '']]}
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
      rclk1:          in std_logic;
      rclk2:          in std_logic;
      locked1:        in std_logic;
      locked2:        in std_logic;

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
   type state_type is (RCLK, IDLE, READY);
   signal state_reg, state_next: state_type;

   -- LFSR signals
   signal lfsr_seed_reg, lfsr_seed_next: integer range 2**11-1 downto 0;
   signal lfsr_seed: std_logic_vector(10 downto 0);
   signal lfsr_load_seed: std_logic;
   signal lfsr_start: std_logic;
begin

   -- state and data register
   process(clk, reset)
   begin
      if (reset = '1') then
         state_reg <= RCLK;
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
         lfsr_seed_reg  <= lfsr_seed_next;
      end if;
   end process;

   -- combinational circuit
   process(state_reg, start, lfsr_seed_reg, rclk1, rclk2, locked1, locked2)
   begin
      state_next     <= state_reg;
      lfsr_seed_next <= lfsr_seed_reg;
      
      lfsr_load_seed <= '0';
      lfsr_start     <= '0';

      case state_reg is
         when RCLK =>
            if (rclk1 = '1' and rising_edge(rclk2)) then
               lfsr_seed_next <= lfsr_seed_reg + 1;
            end if;

            if (locked1 = '1' and locked2 = '1') then
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
            if (read = '1') then
               lfsr_start <= '1';
            end if;

      end case;
   end process;

   lfsr: entity work.LFSR(rtl)
   port map(
      reset     => reset,          -- in
      clk       => clk,            -- in
      start     => lfsr_start,     -- in
      load_seed => lfsr_load_seed, -- in
      seed      => lfsr_seed,      -- in
      retval    => randval         -- out
   );
   lfsr_seed <= std_logic_vector(to_unsigned(lfsr_seed_reg,lfsr_seed'length));

end rtl;
