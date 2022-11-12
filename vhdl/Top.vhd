----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Professor Jim Plusquellic
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    Top - Behavioral 
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

entity Top is
   port (
      Clk: in std_logic;
      reset : in STD_LOGIC;
      GPIO_Ins: in std_logic_vector(31 downto 0);
      GPIO_Outs: out std_logic_vector(31 downto 0);
      PNL_BRAM_addr: out std_logic_vector (12 downto 0);
      PNL_BRAM_din: out std_logic_vector (15 downto 0);
      PNL_BRAM_dout: in std_logic_vector (15 downto 0);
      PNL_BRAM_we: out std_logic_vector (0 to 0);
      hdmi_red : out STD_LOGIC_VECTOR ( 7 downto 0 );
      hdmi_green : out STD_LOGIC_VECTOR ( 7 downto 0 );
      hdmi_blue : out STD_LOGIC_VECTOR ( 7 downto 0 );
      hdmi_hsync : out STD_LOGIC;
      hdmi_vsync : out STD_LOGIC;
      hdmi_enable : out STD_LOGIC;
      sw_r, sw_g, sw_b : in STD_LOGIC;
      pix_en : out STD_LOGIC;
      pix_addr : out STD_LOGIC_VECTOR ( 18 downto 0 ) -- 640x480=307200
  --    DEBUG_IN: in std_logic;
   --   DEBUG_OUT: out std_logic
      );
end Top;

architecture beh of Top is

-- GPIO INPUT BIT ASSIGNMENTS
   constant IN_CP_RESET: integer := 31;
   constant IN_CP_START: integer := 30;
   constant IN_CP_LM_ULM_LOAD_UNLOAD: integer := 26;
   constant IN_CP_LM_ULM_DONE: integer := 25;
   constant IN_CP_HANDSHAKE: integer := 24;

-- GPIO OUTPUT BIT ASSIGNMENTS
   constant OUT_SM_READY: integer := 31;
   constant OUT_SM_HANDSHAKE: integer := 28;

-- Signal declarations
   signal RESET_final: std_logic;

   signal hdmi_hsync_sig : std_logic;
   signal hdmi_vsync_sig : std_logic;
   signal pixel_x : unsigned(10 downto 0);
   signal pixel_y : unsigned(9 downto 0);
   signal prev_x_reg, prev_x_next : unsigned(10 downto 0);
   signal pix_addr_reg, pix_addr_next : unsigned(18 downto 0);

   signal LM_ULM_start, LM_ULM_ready: std_logic;
   signal LM_ULM_stopped, LM_ULM_continue: std_logic;
   signal LM_ULM_done: std_logic;
   signal LM_ULM_base_address: std_logic_vector(PNL_BRAM_ADDR_SIZE_NB-1 downto 0);
   signal LM_ULM_upper_limit: std_logic_vector(PNL_BRAM_ADDR_SIZE_NB-1 downto 0);
   signal LM_ULM_load_unload: std_logic;

   signal DataIn: std_logic_vector(WORD_SIZE_NB-1 downto 0);
   signal DataOut: std_logic_vector(WORD_SIZE_NB-1 downto 0);

-- =======================================================================================================
begin

-- Light up LED if LoadUnLoadMemMod is ready for a command
--   DEBUG_OUT <= LM_ULM_ready;

-- =====================
-- INPUT control and status signals
-- Software (C code) plus hardware global reset
   RESET_final <= GPIO_Ins(IN_CP_RESET) or reset;

-- Start signal from C program. 
   LM_ULM_start <= GPIO_Ins(IN_CP_START);

-- C program controls whether we are loading or unloading memory
   LM_ULM_load_unload <= GPIO_Ins(IN_CP_LM_ULM_LOAD_UNLOAD);

-- C program asserts if done reading or writing memory (or a portion of it)
   LM_ULM_done <= GPIO_Ins(IN_CP_LM_ULM_DONE);

-- Handshake signal
   LM_ULM_continue <= GPIO_Ins(IN_CP_HANDSHAKE);

-- Data from C program
   DataIn <= GPIO_Ins(WORD_SIZE_NB-1 downto 0);

-- =====================
-- OUTPUT control and status signals
-- Tell C program whether LoadUnLoadMemMod is ready 
   GPIO_Outs(OUT_SM_READY) <= LM_ULM_ready; 

-- Handshake signals
   GPIO_Outs(OUT_SM_HANDSHAKE) <= LM_ULM_stopped; 

-- Data to C program
   GPIO_Outs(WORD_SIZE_NB-1 downto 0) <= DataOut;

-- =====================
-- Setup memory base and upper_limit
   LM_ULM_base_address <= std_logic_vector(to_unsigned(PN_BRAM_BASE, PNL_BRAM_ADDR_SIZE_NB));
   LM_ULM_upper_limit <= std_logic_vector(to_unsigned(PNL_BRAM_NUM_WORDS_NB -1, PNL_BRAM_ADDR_SIZE_NB));

-- Secure BRAM access control module
   LoadUnLoadMemMod: entity work.LoadUnLoadMem(beh)
      port map(Clk=>Clk, RESET=>RESET, start=>LM_ULM_start, ready=>LM_ULM_ready, load_unload=>LM_ULM_load_unload, stopped=>LM_ULM_stopped, 
         continue=>LM_ULM_continue, done=>LM_ULM_done, base_address=>LM_ULM_base_address, upper_limit=>LM_ULM_upper_limit, 
         CP_in_word=>DataIn, CP_out_word=>DataOut, 
         PNL_BRAM_addr=>PNL_BRAM_addr, PNL_BRAM_din=>PNL_BRAM_din, PNL_BRAM_dout=>PNL_BRAM_dout, PNL_BRAM_we=>PNL_BRAM_we);


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

--    hdmi_red <= std_logic_vector(resize(pixel_x, 8)) when sw_r = '1' else (others => '0');
--    hdmi_green <= std_logic_vector(resize(pixel_y, 8)) when sw_g = '1' else (others => '0');
    hdmi_red <= "11111111" when sw_r = '1' else (others => '0');
    hdmi_green <= "11111111" when sw_g = '1' else (others => '0');
    hdmi_blue <= "11111111" when sw_b = '1' else (others => '0');
    hdmi_hsync <= hdmi_hsync_sig;
    hdmi_vsync <= hdmi_vsync_sig;
    pix_en <= hdmi_hsync_sig or hdmi_vsync_sig;
    pix_addr <= std_logic_vector(pix_addr_next);

end beh;

