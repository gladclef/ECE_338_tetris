-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : 23.11.2022 07:14:11 UTC

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity tb_Controls is
end tb_Controls;

architecture tb of tb_Controls is

    component Controls
        port (zybo_button_left  : in std_logic;
              zybo_button_right : in std_logic;
              x_increment       : out std_logic_vector (rocket_max_move_rate_nb downto 0));
    end component;

    signal zybo_button_left  : std_logic;
    signal zybo_button_right : std_logic;
    signal x_increment       : std_logic_vector (rocket_max_move_rate_nb downto 0);

    constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : Controls
    port map (zybo_button_left  => zybo_button_left,
              zybo_button_right => zybo_button_right,
              x_increment       => x_increment);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    --  EDIT: Replace YOURCLOCKSIGNAL below by the name of your clock as I haven't guessed it
    --  YOURCLOCKSIGNAL <= TbClock;

    stimuli : process
    begin
        -- initialization
        zybo_button_left <= '0';
        zybo_button_right <= '0';

        -- stimuli
        wait for TbPeriod;
        zybo_button_left <= '1';
        wait for TbPeriod;
        zybo_button_right <= '1';
        wait for TbPeriod;
        zybo_button_left <= '0';
        wait for TbPeriod;
        zybo_button_right <= '0';
        wait for TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_Controls of tb_Controls is
    for tb
    end for;
end cfg_tb_Controls;