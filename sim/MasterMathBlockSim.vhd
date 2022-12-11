-- Testbench created online at:
--   https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
-- Copyright Doulos Ltd

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

library work;
use work.DataTypes_pkg.all;

entity tb_MasterMathBlock is
end;

architecture tb of tb_MasterMathBlock is

   component MasterMathBlock
      Port (
         reset:        in std_logic;
         clk:          in std_logic;
         start:        in std_logic;
         stop:         in std_logic;
         ready:        out std_logic;
         y_increment:  in std_logic_vector(MAX_FALL_RATE_NB-1 downto 0);
         randval:      in std_logic_vector(10 downto 0);
         read_rand:    out std_logic;
         pix_x:        in std_logic_vector(10 downto 0);
         pix_y:        in std_logic_vector(9 downto 0);
         frame_update: in std_logic;
         pix_en:       out std_logic;
         color:        out std_logic_vector(23 downto 0)
      );
   end component;
 
   signal reset: std_logic;
   signal clk: std_logic;
   signal start: std_logic;
   signal stop: std_logic;
   signal ready: std_logic;
   signal y_increment: std_logic_vector(MAX_FALL_RATE_NB-1 downto 0);
   signal randval: std_logic_vector(10 downto 0);
   signal read_rand: std_logic;
   signal pix_x: std_logic_vector(10 downto 0);
   signal pix_y: std_logic_vector(9 downto 0);
   signal frame_update: std_logic;
   signal pix_en: std_logic;
   signal color: std_logic_vector(23 downto 0) ;
 
   constant TbPeriod : time := 40 ns; -- 25MHz
   signal TbClock : std_logic := '0';
   signal TbSimEnded : std_logic := '0';

begin

   uut: MasterMathBlock port map ( reset        => reset,
                                   clk          => clk,
                                   start        => start,
                                   stop         => stop,
                                   ready        => ready,
                                   y_increment  => y_increment,
                                   randval      => randval,
                                   read_rand    => read_rand,
                                   pix_x        => pix_x,
                                   pix_y        => pix_y,
                                   frame_update => frame_update,
                                   pix_en       => pix_en,
                                   color        => color );
 
   -- Clock generation
   TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
 
   -- EDIT: Check that clk is really your main clock signal
   clk <= TbClock;
 
   stimulus: process
   begin
      -- EDIT Adapt initialization as needed
      start <= '0';
      y_increment <= (others => '0');
      randval <= "00011110000";
      pix_x <= (others => '0');
      pix_y <= (others => '0');
      frame_update <= '0';

      -- Reset generation
      -- EDIT: Check that reset is really your reset signal
      reset <= '1';
      wait for 100 ns;
      reset <= '0';
      wait for 100 ns;

      -- EDIT Add stimuli here
      start <= '1';
      wait for 1   * TbPeriod;
      start <= '0';
      for n in 0 to 1000 loop
         frame_update <= '1';
         wait for 1   * TbPeriod;
         frame_update <= '0';
         wait for 25  * TbPeriod;
      end loop;
 
      -- Stop the clock and hence terminate the simulation
      TbSimEnded <= '1';
      wait;
   end process;
 
end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_MasterMathBlock of tb_MasterMathBlock is
    for tb
    end for;
end cfg_tb_MasterMathBlock;