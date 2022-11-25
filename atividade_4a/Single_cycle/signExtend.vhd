--SignExtend
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signExtend is
    port(
        Instr_D  : in  std_logic_vector(31 downto 7); 
        ImmSrc_D : in  std_logic_vector(1 downto 0);
        ImmExt_D : out std_logic_vector(31 downto 0) 
    );
end signExtend;

architecture behavioral_se of signExtend is

    signal Instr_00 : std_logic_vector(11 downto 0);
    signal Instr_01 : std_logic_vector(11 downto 0);
    signal Instr_10 : std_logic_vector(12 downto 0);

begin

    Instr_00 <= Instr_D(31 downto 20);
    Instr_01 <= Instr_D(31 downto 25) & Instr_D(11 downto 7);
    Instr_10 <= Instr_D(31) & Instr_D(7) & Instr_D(30 downto 25) & Instr_D(11 downto 8) & '0';

    ImmExt_D <= std_logic_vector(resize(signed(Instr_00), 32)) when (ImmSrc_D = "00") else
                std_logic_vector(resize(signed(Instr_01), 32)) when (ImmSrc_D = "01") else
                std_logic_vector(resize(signed(Instr_10), 32)) when (ImmSrc_D = "10") else
                (others => '0');


end behavioral_se ; -- behavioral