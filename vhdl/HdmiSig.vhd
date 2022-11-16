----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Rachel Cazzola, Benjamin Bean
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    hdmi_sig - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

-- ===================================================================================================
-- ===================================================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

library work;
use work.DataTypes_pkg.all;

entity hdmi_sig is
   port (
      clk: in std_logic;
      reset : in STD_LOGIC;
      hdmi_hsync : out STD_LOGIC;
      hdmi_vsync : out STD_LOGIC;
      hdmi_enable : out STD_LOGIC;
      pix_en : out STD_LOGIC;
      pix_x : out STD_LOGIC_VECTOR(10 downto 0);
      pix_y : out STD_LOGIC_VECTOR(9 downto 0);
      pix_addr : out STD_LOGIC_VECTOR ( 18 downto 0 ) -- 640x480=307200, log(307200)=19
   );
end hdmi_sig;

architecture beh of hdmi_sig is

   signal hdmi_hsync_sig : std_logic;
   signal hdmi_vsync_sig : std_logic;
   signal pixel_x : unsigned(10 downto 0);
   signal pixel_y : unsigned(9 downto 0);
   signal prev_x_reg, prev_x_next : unsigned(10 downto 0);
   signal pix_addr_reg, pix_addr_next : unsigned(18 downto 0);

-- =======================================================================================================
begin

   -- =====================
   hdmi_sync_i: entity work.hdmi_sync(rtl)
   port map (
      clk => clk,
      reset => reset,
      hdmi_hsync => hdmi_hsync_sig,
      hdmi_vsync => hdmi_vsync_sig,
      hdmi_enable => hdmi_enable,
      pixel_x => pixel_x,
      pixel_y => pixel_y
   );

   process (clk, reset)
   begin
      if (reset = '1') then
         prev_x_reg <= (others => '0');
         pix_addr_reg <= (others => '0');
      elsif (rising_edge(clk)) then
         prev_x_reg <= prev_x_next;
         pix_addr_reg <= pix_addr_next;
      end if;
   end process;

   process (hdmi_hsync_sig, hdmi_vsync_sig)
   begin
      prev_x_next <= pixel_x;
      pix_addr_next <= pix_addr_reg;

      if (pixel_x = 0) then
         pix_addr_next <= (others => '0');
      elsif (pixel_x /= prev_x_reg) then
         pix_addr_next <= pix_addr_reg + 1;
      end if;
   end process;

   hdmi_hsync <= hdmi_hsync_sig;
   hdmi_vsync <= hdmi_vsync_sig;
   pix_en   <= hdmi_hsync_sig or hdmi_vsync_sig;
   pix_x    <= std_logic_vector(pixel_x);
   pix_y    <= std_logic_vector(pixel_y);
   pix_addr <= std_logic_vector(pix_addr_next);

end beh;

