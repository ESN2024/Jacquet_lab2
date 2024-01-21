library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity BCD7SEG is
    port (
		bin_in : in  STD_LOGIC_VECTOR (3 downto 0);
        seg_out : out  STD_LOGIC_VECTOR (6 downto 0));
end BCD7SEG;

architecture Behavioral of BCD7SEG is
begin
    process(bin_in)
    begin
        case bin_in is
            when "0000" => seg_out <= "1000000"; -- 0 -- le 7 segment est sensible au niveau logique bas
            when "0001" => seg_out <= "1111001"; -- 1
            when "0010" => seg_out <= "0100100"; -- 2
            when "0011" => seg_out <= "0110000"; -- 3
            when "0100" => seg_out <= "0011001"; -- 4
            when "0101" => seg_out <= "0010010"; -- 5
            when "0110" => seg_out <= "0000010"; -- 6
            when "0111" => seg_out <= "1111000"; -- 7
            when "1000" => seg_out <= "0000000"; -- 8
            when "1001" => seg_out <= "0010000"; -- 9
            when others => seg_out <= "1111111"; -- eteint
        end case;
    end process;
end Behavioral;