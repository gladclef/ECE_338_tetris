-- Ben Bean
-----------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Benjamin Bean, Rachel Cazzola
-- 
-- Module Name:    RNG_TRNG - behavioral
-- Description:    A true random number generator which helps contribute to the randomness for the RNG.
--                 Generate random noise from the timing of the locked signal from an MMCM.
--                 
--                 To use this module, first create a clock wizard with the name "clk_wiz_1" and with
--                 ports "clk_in1", "reset", "clk_out1", and "locked". Then add this module and the RNG
--                 module to your project.
--
-----------------------------------------------------------
-- FSM created with https://github.com/gladclef/FSMs
-- {'fsm_name': 'TRNG', 'table_vals': [['', 'locked', '__', ''], ['WAIT_LOCKED', 'READY', '', ''], ['READY', '', 'WAIT_LOCKED', ''], ['', '', '', '']]}
-----------------------------------------------------------

-- TRNG generates truly random number values

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity TRNG is
   Port (
      -- standard values
      clk:         in std_logic;

      -- rclk values
      rclk_locked: in std_logic;
      rclk_resetn: out std_logic;

      -- results
      new_rval:    out std_logic; -- goes high for one clock cycle when there is a new value for "rval"
      rval:        out std_logic_vector(10 downto 0) -- the truly random value
   );
end TRNG;

architecture rtl of TRNG is
   type state_type is (WAIT_LOCKED, READY);
   signal state_reg, state_next: state_type;

   -- counter
   signal cnt_reg, cnt_next: integer range 0 to 2**rval'length-1;
begin

   -- state and data register
   process(clk)
   begin
      if (rising_edge(clk)) then
         state_reg <= state_next;
         cnt_reg   <= cnt_next;
      end if;
   end process;

   -- combinational circuit
   process(state_reg, rclk_locked, cnt_reg)
   begin
      state_next  <= state_reg;
      rclk_resetn <= '1';
      new_rval    <= '0';
      cnt_next    <= cnt_reg;

      case state_reg is
         when WAIT_LOCKED =>
            cnt_next <= cnt_reg + 1;
            if (rclk_locked = '1') then
               state_next <= READY;
            end if;

         when READY =>
            rclk_resetn <= '0';
            new_rval    <= '1';
            state_next  <= WAIT_LOCKED;

      end case;
   end process;

   -- always output the current count
   rval <= std_logic_vector(to_unsigned(cnt_reg, rval'length));

end rtl;
