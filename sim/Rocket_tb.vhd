-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : 23.11.2022 00:21:12 UTC

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_Rocket is
end tb_Rocket;

library work;
use work.DataTypes_pkg.all;

architecture tb of tb_Rocket is

    component Rocket
        port (reset        : in std_logic;
              clk          : in std_logic;
              start        : in std_logic;
              x_increment  : in std_logic_vector (rocket_max_move_rate_nb downto 0);
              pix_x        : in std_logic_vector (screen_width_nb-1 downto 0);
              pix_y        : in std_logic_vector (screen_height_nb-1 downto 0);
              frame_update : in std_logic;
              stop         : in std_logic;
              x_mid        : out std_logic_vector (screen_width_nb-1 downto 0);
              pix_en       : out std_logic;
              color        : out std_logic_vector (23 downto 0));
    end component;

    signal reset        : std_logic;
    signal clk          : std_logic;
    signal start        : std_logic;
    signal x_increment  : std_logic_vector (rocket_max_move_rate_nb downto 0);
    signal pix_x        : std_logic_vector (screen_width_nb-1 downto 0);
    signal pix_y        : std_logic_vector (screen_height_nb-1 downto 0);
    signal frame_update : std_logic;
    signal stop         : std_logic;
    signal x_mid        : std_logic_vector (screen_width_nb-1 downto 0);
    signal pix_en       : std_logic;
    signal color        : std_logic_vector (23 downto 0);

    constant TbPeriod : time := 40 ns;
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : Rocket
    port map (reset        => reset,
              clk          => clk,
              start        => start,
              x_increment  => x_increment,
              pix_x        => pix_x,
              pix_y        => pix_y,
              frame_update => frame_update,
              stop         => stop,
              x_mid        => x_mid,
              pix_en       => pix_en,
              color        => color);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;

    stimuli : process
    begin
        -- initialization
        start <= '0';
        x_increment <= (others => '0');
        pix_x <= (others => '0');
        pix_y <= (others => '0');
        frame_update <= '0';
        stop <= '0';

        -- Reset generation
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- stimuli
        start <= '1';
        for y in ROCKET_Y-2 to SCREEN_HEIGHT loop
            for x in ROCKET_X-2 to ROCKET_X+ROCKET_WIDTH+4 loop
                pix_x <= std_logic_vector(to_unsigned(x,pix_x'length));
                pix_y <= std_logic_vector(to_unsigned(y,pix_y'length));
                wait for TbPeriod;
            end loop;
        end loop;

        wait for TbPeriod * 100;

        x_increment <= std_logic_vector(to_signed(1,x_increment'length));
        for x in 320 to 650 loop
            frame_update <= '1';
            wait for TbPeriod;
            frame_update <= '0';
            wait for TbPeriod;
        end loop;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_Rocket of tb_Rocket is
    for tb
    end for;
end cfg_tb_Rocket;