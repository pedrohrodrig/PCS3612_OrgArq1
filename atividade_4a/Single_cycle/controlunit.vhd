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
        opcode       : in std_logic_vector(6 downto 0)
    );
end entity;

architecture behavioral_uc of controlunit is

    component maindec is
        port(
            op: in std_logic_vector(6 downto 0);
            ResultSrc: out std_logic_vector(1 downto 0);
            MemWrite: out std_logic;
            Branch, ALUSrc: out std_logic;
            RegWrite, Jump: out std_logic;
            ImmSrc: out std_logic_vector(1 downto 0);
            ALUOp: out std_logic_vector(1 downto 0)
        );
    end component;

    signal LDUR, STUR, CBZ : std_logic;
    signal aluop_s, immSrc_s, resultSrc_s : std_logic_vector(1 downto 0);
    signal branch_s, memWrite_s, aluSrc_s, regWrite_s, jump_s: std_logic; 

begin

    decoder: maindec
    port map(
        op         => opcode, 
        ResultSrc  => resultSrc_s, 
        MemWrite   => memWrite_s,
        Branch     => branch_s, 
        ALUSrc     => aluSrc_s, 
        RegWrite   => regWrite_s, 
        Jump       => jump_s, 
        ImmSrc     => immSrc_s,
        ALUOp      => aluop_s
    );

    LDUR <= '1' when opcode = "0000011" else '0';
    STUR <= '1' when opcode = "0100011" else '0';
    CBZ  <= '1' when opcode = "1100011" else '0';

    reg2loc      <= STUR or CBZ;
    uncondBranch <= jump_s;
    branch       <= branch_s;
    memRead      <= LDUR;
    memToReg     <= LDUR;
    memWrite     <= memWrite_s;
    aluSRC       <= aluSrc_s;
    regWrite     <= regWrite_s;
    aluOp <= aluop_s

end behavioral_uc ; -- behavioral