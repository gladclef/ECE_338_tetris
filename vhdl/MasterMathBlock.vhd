library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.DataTypes_pkg.all;

entity MasterMathBlock is
    Port (
      reset:        in std_logic;
      clk:          in std_logic;
      ready:        out std_logic;
      start:        in std_logic;
      x:            in std_logic_vector(10 downto 0);
      ascii:        in std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
      y_increment:  in std_logic_vector(MAX_FALL_RATE_NB-1 downto 0);
      stop:         in std_logic;
      pix_x:        in std_logic_vector(10 downto 0);
      pix_y:        in std_logic_vector(9 downto 0);
      frame_update: in std_logic;
      pix_en:       out std_logic;
      color:        out std_logic_vector(23 downto 0)    
    );
end MasterMathBlock;

architecture rtl of MasterMathBlock is    

    type std_logic_array is array(0 to 3) of std_logic;
    type vectorX_Array is array(0 to 3) of std_logic_vector(10 downto 0);
	type vectorAsciiArray is array(0 to 3) of std_logic_vector(MATH_BLOCK_MAX_CHARS*ASCII_NB-1 downto 0);
	type vectorColorArray is array(0 to 3) of std_logic_vector(23 downto 0);
	
	signal readys : std_logic_array;
	signal starts : std_logic_array;
	signal xs : vectorX_Array;
	signal asciis : vectorAsciiArray;
	signal pix_ens : std_logic_array;
	signal colors : vectorColorArray;
	
    begin
   
   for_generate_math_block: for i in 0 to 3 generate
   
		MathBlock: entity work.MathBlock(rtl)
		port map (
			reset => reset,
			clk => clk,
			ready => readys(i),
			start => starts(i),
			x => xs(i),
			ascii => asciis(i), 
			y_increment => y_increment, 
			stop => stop,
			pix_x => pix_x,
			pix_y => pix_y,
			frame_update => frame_update, 
			pix_mb_en => pix_ens(i),
			color => colors(i)   
		);
   end generate for_generate_math_block;
   
   process(ascii, pix_ens)
		
		variable pix_en_any : std_logic;
		
		begin
		
		pix_en_any := '0';
   
		for i in 0 to 3 loop
			starts(i) <= '1'; 
			xs(i) <= std_logic_vector(to_unsigned(i*50, 11));
			asciis(i) <= ascii; 
			pix_en_any := pix_ens(i) or pix_en_any;
		end loop;
		
        pix_en <= pix_en_any;
        
   end process;
   
   color <= colors(0);
   
end rtl;