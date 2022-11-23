--Controle da ULA
entity alucontrol is
    port(
        aluop   : in bit_vector(1 downto 0);
        opcode  : in bit_vector(10 downto 0);
        aluCtrl : out bit_vector(3 downto 0)
    );
end entity;

architecture behavioral_aluc of alucontrol is

begin

    aluCtrl <=
        "0010" when aluop = "00"                              else 
        "0111" when aluop(0) = '1'                            else 
        "0010" when aluop(1) = '1' and opcode = "10001011000" else
        "0110" when aluop(1) = '1' and opcode = "11001011000" else
        "0000" when aluop(1) = '1' and opcode = "10001010000" else
        "0001" when aluop(1) = '1' and opcode = "10101010000" else
        "0000";

end behavioral_aluc ; 