library ieee;
use ieee.std_logic_1164.all;

entity controlunit is
    port(
        -- From Datapath
        opcode         : in std_logic_vector(6 downto 0);
        funct3         : in std_logic_vector(2 downto 0);
        funct7b5       : in std_logic;
        -- To Datapath
        RegWrite_D     : out std_logic;
        ResultSrc_D    : out std_logic_vector(1 downto 0);
        MemWrite_D     : out std_logic;
        Jump_D         : out std_logic;
        Branch_D       : out std_logic;
        ALUControl_D   : out std_logic_vector(2 downto 0);
        ALUSrc_D       : out std_logic;
        ImmSrc_D       : out std_logic_vector(1 downto 0)
    );
end entity;

architecture behavioral_uc of controlunit is

    component maindec is
        port(
            op             : in  std_logic_vector(6 downto 0);
            ResultSrc      : out std_logic_vector(1 downto 0);
            MemWrite       : out std_logic;
            Branch, ALUSrc : out std_logic;
            RegWrite, Jump : out std_logic;
            ImmSrc         : out std_logic_vector(1 downto 0);
            ALUOp          : out std_logic_vector(1 downto 0)
        );
    end component;

    component aludec is
        port(
            opb5     : in std_logic;
            funct7b5 : in std_logic;
            funct3   : in std_logic_vector(2 downto 0);
            aluop    : in std_logic_vector(1 downto 0);
            aluCtrl  : out std_logic_vector(2 downto 0)
        );
    end component;

    signal LDUR, STUR, CBZ                                    : std_logic;
    signal aluop_s, immSrc_s, resultSrc_s                     : std_logic_vector(1 downto 0);
    signal branch_s, memWrite_s, aluSrc_s, regWrite_s, jump_s : std_logic;
    signal aluControl_s                                       : std_logic_vector(2 downto 0);

begin

    main_decoder: maindec
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

    alu_decoder: aludec
    port map(
        opb5     => opcode(5),
        funct7b5 => funct7b5,
        funct3   => funct3,
        aluop    => aluop_s,
        aluCtrl  => aluControl_s
    );

    RegWrite_D   <= regWrite_s;
    ResultSrc_D  <= resultSrc_s;
    MemWrite_D   <= memWrite_s;
    Jump_D       <= jump_s;
    Branch_D     <= branch_s;
    ALUControl_D <= aluControl_s;
    ALUSrc_D     <= aluSrc_s;
    ImmSrc_D     <= immSrc_s;

end behavioral_uc ; -- behavioral