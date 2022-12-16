library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

-- Rachel Cazzola
entity ScoreCounter is
   Port (
        clk, reset: in std_logic;
        score_increase: in std_logic;
        score_digit0, score_digit1 : out std_logic_vector(5 downto 0)
        );
end ScoreCounter;

architecture rtl of ScoreCounter is

   --signals for updating score
   signal score_digit0_reg, score_digit1_reg: std_logic_vector(5 downto 0);
   signal score_digit0_next, score_digit1_next: std_logic_vector(5 downto 0);
   signal score_reg, score_next: integer range 0 to 99;
   
begin 

    -- state and data register for updating score
   process(clk, reset)
   begin
      if (reset = '1') then
        score_digit0_reg <= ASCII_2;--(others => '0');
        score_digit1_reg <= ASCII_1;--(others => '0');
        score_reg <= 0;
      elsif (rising_edge(clk)) then
         score_digit0_reg <= score_digit0_next;
         score_digit1_reg <= score_digit1_next;
         score_reg <= score_next;
      end if;
   end process;      
   
   -- combinational circuit
   process(score_increase, score_digit0_reg, score_digit1_reg, score_reg)
   
   begin
         
      if (score_increase = '1') then
        score_next <= score_reg+1;
      end if;
    end process;
      
      score_digit0 <= std_logic_vector(score_digit0_reg);
      score_digit1 <= std_logic_vector(score_digit1_reg);
      score_digit0_next <= std_logic_vector(to_unsigned(48 + score_reg mod 10,ASCII_NB));
      score_digit1_next <= std_logic_vector(to_unsigned(48 + score_reg / 10,ASCII_NB)); 
            
end rtl;        