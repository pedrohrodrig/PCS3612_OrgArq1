library ieee;
use ieee.std_logic_1164.all;

entity controlunit is
    port(
        -- To Datapath
        reg2loc      : out std_logic;
        uncondBranch : out std_logic;
        branch       : out std_logic;
        memRead      : out std_logic;
        memToReg     : out std_logic;
        aluOp        : out std_logic_vector(1 downto 0);
        memWrite     : out std_logic;
        aluSrc       : out std_logic;
        regWrite     : out std_logic;
        -- From Datapath
        opcode       : in std_logic_vector(10 downto 0)
    );
end entity;

architecture behavioral_uc of controlunit is

    signal Rf, LDUR, STUR, CBZ, B : std_logic;

begin

    Rf   <= '1' when (opcode(10) = '1' and opcode(7 downto 4) = "0101" and opcode(2 downto 0) = "000") else '0';
    LDUR <= '1' when opcode = "11111000010" else '0';
    STUR <= '1' when opcode = "11111000000" else '0';
    CBZ  <= '1' when opcode(10 downto 3) = "10110100" else '0';
    B    <= '1' when opcode(10 downto 5) = "000101" else '0';

    reg2loc      <= STUR or CBZ;
    uncondBranch <= B;
    branch       <= CBZ;
    memRead      <= LDUR;
    memToReg     <= LDUR;
    memWrite     <= STUR;
    aluSRC       <= LDUR or STUR;
    regWrite     <= LDUR or Rf;

    aluOp <= "00" when (LDUR or STUR) = '1' else
             "01" when CBZ = '1'            else
             "10" when Rf = '1'             else
             "11";

end behavioral_uc ; -- behavioral