library ieee;
use ieee.std_logic_1164.all;

--Controle da ULA
entity aludec is
    port(
        opb5     : in std_logic;
        funct7b5 : in std_logic;
        funct3   : in std_logic_vector(2 downto 0);
        aluop    : in std_logic_vector(1 downto 0);
        aluCtrl  : out std_logic_vector(2 downto 0)
    );
end entity;

architecture behavioral_aludec of aludec is
    signal RtypeSub: std_logic;
begin

    RtypeSub <= funct7b5 and opb5; 
    process(opb5, funct3, funct7b5, aluop, RtypeSub) 
    begin 
        case aluop is
            when "00" => aluCtrl <= "000"; --add
            when "01" => aluCtrl <= "001"; --subtraction 
            when others => --R-type
            case funct3 is 
                when "000" => 
                    if RtypeSub = '1' then 
                        aluCtrl <= "001"; --sub
                    else 
                        aluCtrl <= "000"; --add, addi
                    end if; 
                when "010" => aluCtrl <= "101"; --slt, slti
                when "110" => aluCtrl <= "011"; --or, ori
                when "111" => aluCtrl <= "010";
                when others => aluCtrl <= "---";
            end case;
        end case;
    end process;
end behavioral_aludec ; 