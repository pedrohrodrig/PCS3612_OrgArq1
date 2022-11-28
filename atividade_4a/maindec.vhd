library ieee;
use ieee.std_logic_1164.all;

entity maindec is
    port(
        op             : in  std_logic_vector(6 downto 0);
        ResultSrc      : out std_logic_vector(1 downto 0);
        MemWrite       : out std_logic;
        Branch, ALUSrc : out std_logic;
        RegWrite, Jump : out std_logic;
        ImmSrc         : out std_logic_vector(1 downto 0);
        ALUOp          : out std_logic_vector(1 downto 0)
    );
end;

architecture behave of maindec is
    signal controls: std_logic_vector(10 downto 0);
begin
    process(op) 
        begin
        case op is
            when "0000011" => controls <= "10010010000"; -- lw
            when "0100011" => controls <= "00111000000"; -- sw
            when "0110011" => controls <= "10000000100"; -- Rtype
            when "1100011" => controls <= "01000001010"; -- beq
            when "0010011" => controls <= "10010000100"; -- Itype ALU
            when "1101111" => controls <= "11100100001"; -- jal
            when others    => controls <= "00000000000"; -- not valid
        end case;
    end process;

    (RegWrite, ImmSrc(1), ImmSrc(0), ALUSrc, MemWrite,
    ResultSrc(1), ResultSrc(0), Branch, ALUOp(1), ALUOp(0),
    Jump) <= controls;
end;