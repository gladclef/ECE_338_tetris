----------------------------------------------------------------------------------
-- Company: University of New Mexico
-- Engineer: Benjamin Bean
-- 
-- Module Name:    LFSR - Behavioral 
-- Description:    Generates pseudo-random numbers, similarly to the LFSR_11bit.c
--                 file that Dr. Plusquellic handed out.
--                 The pseudo random value will be ready one clock cycle after
--                 start gets asserted.
--
----------------------------------------------------------------------------------

-- LFSR Generates pseudo-random numbers in one clock cycle.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

library work;
use work.DataTypes_pkg.all;

entity LFSR is
   port( 
      reset:     in std_logic;
      clk:       in std_logic;
      start:     in std_logic; -- must be held high for a clock cycle
      load_seed: in std_logic; -- assert to change the internal value to seed (aka on the first iteration)
      seed:      in std_logic_vector(10 downto 0);
      retval:    out std_logic_vector(10 downto 0);
      valid:     out std_logic -- will be asserted one clock cycle after start
   );
end LFSR;

architecture rtl of LFSR is
   signal lfsr_reg, lfsr_next:   std_logic_vector(10 downto 0);
   signal valid_reg, valid_next: std_logic;
begin

   -- =============================================================================================
   -- State and register logic
   -- =============================================================================================
   process(clk, reset)
   begin
      if ( reset = '1' ) then
         lfsr_reg  <= (others => '0');
         valid_reg <= '0';
      elsif (rising_edge(clk)) then
         lfsr_reg  <= lfsr_next;
         valid_reg <= valid_next;
      end if; 
   end process;

   -- =============================================================================================
   -- Combo logic
   -- =============================================================================================
   process (start, load_seed, seed, lfsr_reg)
      variable nor_bit:   std_logic;
      variable next_bit:  std_logic;
   begin
      -- retain register values
      lfsr_next <= lfsr_reg;

      -- default register values
      valid_next <= '0';

      -- when start is received, calculate lfsr_next
      if (start = '1') then
         if (load_seed = '1') then
            lfsr_next <= seed;
         else
            nor_bit := '0';
            if (lfsr_reg(9 downto 0) = "0000000000") then
               nor_bit := '1';
            end if;

            next_bit := lfsr_reg(10) xor lfsr_reg(8) xor nor_bit;

            lfsr_next <= lfsr_reg(9 downto 0) & next_bit;
            valid_next <= '1';
         end if;
      end if;
   end process;

   retval <= lfsr_reg;
end rtl;

--uint16_t LFSR_11_A_bits(int load_seed, uint16_t seed)
--{
--   static uint16_t lfsr;
--   uint16_t bit, nor_bit;

--   // Load the seed on the first iteration.
--   if ( load_seed == 1 ) {
--      lfsr = seed;
--   } else {

--      // Allow all zero state. See my BIST class notes in VLSI Testing. Note, we use low order bits
--      // here because bit is shifted onto the low side, not high side as in my lecture slides.
--      if ( !( (((lfsr >> 9) & 1) == 1) || (((lfsr >> 8) & 1) == 1) ||
--              (((lfsr >> 7) & 1) == 1) || (((lfsr >> 6) & 1) == 1) || (((lfsr >> 5) & 1) == 1) ||
--              (((lfsr >> 4) & 1) == 1) || (((lfsr >> 3) & 1) == 1) || (((lfsr >> 2) & 1) == 1) ||
--              (((lfsr >> 1) & 1) == 1) || (((lfsr >> 0) & 1) == 1) ) )
--         nor_bit = 1;
--      else
--         nor_bit = 0;

--      // xor_out := rand(10) xor rand(8)
--      bit  = ((lfsr >> 10) & 1) ^ ((lfsr >> 8) & 1) ^ nor_bit;

--      // printf("LFSR value %d\tNOR bit value %d\tlow order bit %d\n", lfsr, nor_bit, bit);

--      // Shift in the bit. Convert 16-bit to 11-bit quantity.
--      lfsr = ((lfsr << 1) | bit) & 2047;
--   }

--   return lfsr;
--}