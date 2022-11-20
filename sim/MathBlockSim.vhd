-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : 20.11.2022 20:14:42 UTC

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity tb_MathBlock is
end tb_MathBlock;

architecture tb of tb_MathBlock is

    component MathBlock
        port (reset       : in std_logic;
              clk         : in std_logic;
              ready       : out std_logic;
              start       : in std_logic;
              x           : in std_logic_vector (10 downto 0);
              ascii       : in std_logic_vector (MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
              y_increment : in std_logic_vector (MAX_FALL_RATE_NB-1 downto 0);
              stop        : in std_logic;
              pix_x       : in std_logic_vector (10 downto 0);
              pix_y       : in std_logic_vector (9 downto 0);
              pix_en      : out std_logic;
              color       : out std_logic_vector (23 downto 0));
    end component;

    signal reset       : std_logic;
    signal clk         : std_logic;
    signal ready       : std_logic;
    signal start       : std_logic;
    signal x           : std_logic_vector (10 downto 0);
    signal ascii       : std_logic_vector (MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
    signal y_increment : std_logic_vector (MAX_FALL_RATE_NB-1 downto 0);
    signal stop        : std_logic;
    signal pix_x       : std_logic_vector (10 downto 0);
    signal pix_y       : std_logic_vector (9 downto 0);
    signal pix_en      : std_logic;
    signal color       : std_logic_vector (23 downto 0);

    constant TbPeriod : time := 40 ns; -- 25MHz
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : MathBlock
    port map (reset       => reset,
              clk         => clk,
              ready       => ready,
              start       => start,
              x           => x,
              ascii       => ascii,
              y_increment => y_increment,
              stop        => stop,
              pix_x       => pix_x,
              pix_y       => pix_y,
              pix_en      => pix_en,
              color       => color);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        start <= '0';
        x <= (others => '0');
        ascii <= (others => '0');
        y_increment <= (others => '0');
        stop <= '0';
        pix_x <= (others => '0');
        pix_y <= (others => '0');

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
        wait for 100 * TbPeriod;
        start <= '0';
        for y_idx in 0 to MATH_BLOCK_HEIGHT+10 loop
            for x_idx in 0 to MATH_BLOCK_MAX_WIDTH+10 loop
                pix_x <= std_logic_vector(to_unsigned(x_idx,pix_x'length));
                pix_y <= std_logic_vector(to_unsigned(y_idx,pix_y'length));
                wait for TbPeriod;
            end loop;
        end loop;
        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_MathBlock of tb_MathBlock is
    for tb
    end for;
end cfg_tb_MathBlock;