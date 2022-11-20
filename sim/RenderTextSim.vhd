-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : 20.11.2022 21:06:40 UTC

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity tb_RenderText is
end tb_RenderText;

architecture tb of tb_RenderText is

    component RenderText
        port (reset  : in std_logic;
              clk    : in std_logic;
              start  : in std_logic;
              ascii  : in std_logic_vector (MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
              count  : out std_logic_vector(MATH_BLOCK_MAX_CHARS_NB-1 downto 0);
              pixels : out std_logic_vector (0 to TEXT_BLOCK_ADDR-1);
              ready  : out std_logic);
    end component;

    signal reset  : std_logic;
    signal clk    : std_logic;
    signal start  : std_logic;
    signal ascii  : std_logic_vector (MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
    signal count  : std_logic_vector(MATH_BLOCK_MAX_CHARS_NB-1 downto 0);
    signal pixels : std_logic_vector (0 to TEXT_BLOCK_ADDR-1);
    signal pixels_expected : std_logic_vector (0 to TEXT_BLOCK_ADDR-1);
    signal ready  : std_logic;

    constant TbPeriod : time := 40 ns; -- 25MHz
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : RenderText
    port map (reset  => reset,
              clk    => clk,
              start  => start,
              ascii  => ascii,
              count  => count,
              pixels => pixels,
              ready  => ready);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- compare to expected value
        pixels_expected <= "10100000111000001110" & "000000000000" &
                           "10100100100001101010" & "000000000000" &
                           "11101110111000001110" & "000000000000" &
                           "00100100001001100010" & "000000000000" &
                           "00100000111000000010" & "000000000000";

        -- EDIT Adapt initialization as needed
        start <= '0';
        ascii <= (others => '0');

        -- Reset generation
        -- EDIT: Check that reset is really your reset signal
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- EDIT Add stimuli here
        start <= '1';
        --                                   9        =        5        +        4
        ascii <= "000000"&"000000"&"000000"&"111001"&"111101"&"110101"&"101011"&"110100";
        wait for TbPeriod;
        start <= '0';
        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_RenderText of tb_RenderText is
    for tb
    end for;
end cfg_tb_RenderText;