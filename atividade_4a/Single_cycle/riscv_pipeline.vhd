library ieee;
use ieee.std_logic_1164.all;

entity riscv_pipeline is
    port (
        clock : in std_logic;
        reset : in std_logic;
        -- IM Interface
        IM_Addr     : out std_logic_vector(31 downto 0);
        IM_ReadData : in  std_logic_vector(31 downto 0); 
        -- DM Interface
        DM_WriteEnable : out std_logic;
        DM_Addr        : out std_logic_vector(31 downto 0);
        DM_WriteData   : out std_logic_vector(31 downto 0);
        DM_ReadData    : in  std_logic_vector(31 downto 0)
    );
end entity;

architecture riscv_pipeline_behavioral of riscv_pipeline is
    
    component controlunit is
        port(
            -- From Datapath
            opcode       : in std_logic_vector(6 downto 0);
            funct3       : in std_logic_vector(2 downto 0);
            funct7b5     : in std_logic;
            -- To Datapath
            RegWrite_D   : out std_logic;
            ResultSrc_D  : out std_logic_vector(1 downto 0);
            MemWrite_D   : out std_logic;
            Jump_D       : out std_logic;
            Branch_D     : out std_logic;
            ALUControl_D : out std_logic_vector(2 downto 0);
            ALUSrc_D     : out std_logic;
            ImmSrc_D     : out std_logic_vector(1 downto 0)
        );
    end component;

    component datapath is
        port(
            -- Common
            clock : in std_logic;
            reset : in std_logic;
    
            -- From Control Unit
            RegWrite_D   : in std_logic;
            ResultSrc_D  : in std_logic_vector(1 downto 0);
            MemWrite_D   : in std_logic;
            Jump_D       : in std_logic;
            Branch_D     : in std_logic;
            ALUControl_D : in std_logic_vector(2 downto 0);
            ALUSrc_D     : in std_logic;
            ImmSrc_D     : in std_logic_vector(1 downto 0);
    
            -- To Control Unit
            opcode : out std_logic_vector(6 downto 0);
            funct3 : out std_logic_vector(2 downto 0);
            funct7 : out std_logic;
    
            -- IM Interface
            IM_Addr     : out std_logic_vector(31 downto 0);
            IM_ReadData : in  std_logic_vector(31 downto 0); --Instrução coletada da memória de intruções
    
            -- DM Interface
            DM_WriteEnable : out std_logic;
            DM_Addr        : out std_logic_vector(31 downto 0);
            DM_WriteData   : out std_logic_vector(31 downto 0);
            DM_ReadData    : in  std_logic_vector(31 downto 0)
        );
    end component;

    signal s_opcode       : std_logic_vector(6 downto 0);
    signal s_funct3       : std_logic_vector(2 downto 0);
    signal s_funct7       : std_logic;
    signal s_RegWrite_D   : std_logic;
    signal s_ResultSrc_D  : std_logic_vector(1 downto 0);
    signal s_MemWrite_D   : std_logic;
    signal s_Jump_D       : std_logic;
    signal s_Branch_D     : std_logic;
    signal s_ALUControl_D : std_logic_vector(2 downto 0);
    signal s_ALUSrc_D     : std_logic;
    signal s_ImmSrc_D     : std_logic_vector(1 downto 0); 

begin
    
    UC: controlunit
        port(
            opcode       => s_opcode,
            funct3       => s_funct3,
            funct7b5     => s_funct7,
            RegWrite_D   => s_RegWrite_D,
            ResultSrc_D  => s_ResultSrc_D,
            MemWrite_D   => s_MemWrite_D,
            Jump_D       => s_Jump_D,
            Branch_D     => s_Branch_D,
            ALUControl_D => s_ALUControl_D,
            ALUSrc_D     => s_ALUSrc_D,
            ImmSrc_D     => s_ImmSrc_D
        );

    FD: datapath
        port map (
            -- Common
            clock => clock,
            reset => reset,

            -- From Control Unit
            RegWrite_D   => s_RegWrite_D,
            ResultSrc_D  => s_ResultSrc_D,
            MemWrite_D   => s_MemWrite_D,
            Jump_D       => s_Jump_D,
            Branch_D     => s_Branch_D,
            ALUControl_D => s_ALUControl_D,
            ALUSrc_D     => s_ALUSrc_D,
            ImmSrc_D     => s_ImmSrc_D,

            -- To Control Unit
            opcode => s_opcode, 
            funct3 => s_funct3, 
            funct7 => s_funct7, 

            -- IM Interface
            IM_Addr     => IM_Addr,
            IM_ReadData => IM_ReadData,

            -- DM Interface
            DM_WriteEnable => DM_WriteEnable,
            DM_Addr        => DM_Addr,
            DM_WriteData   => DM_WriteData,
            DM_ReadData    => DM_ReadData   
        );
    
end architecture riscv_pipeline_behavioral;