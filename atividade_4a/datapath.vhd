--Fluxo de dados
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

entity datapath is
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
end entity datapath;

architecture PoliLeg_FD of datapath is

    component ALU is 
        generic (
            word_size : natural := 64
        );
        port (
            A          : in  std_logic_vector(word_size-1 downto 0);
            B          : in  std_logic_vector(word_size-1 downto 0);
            ALUControl : in  std_logic_vector(2 downto 0);
            Result     : out std_logic_vector(word_size-1 downto 0);
            Overflow   : out std_logic;
            CarryOut   : out std_logic;
            Negative   : out std_logic;
            Zero       : out std_logic
        );
    end component;

    component regfile is
        generic(
            regn     : natural := 32; -- numero de registradores
            wordSize : natural := 64
        );
        port(
            clock        : in std_logic;
            reset        : in std_logic;
            regWrite     : in std_logic;
            rr1, rr2, wr : in std_logic_vector(natural(ceil(log2(real(regn))))-1 downto 0); -- std_logic_vector(log2(regn)-1 downto 0)
            d            : in std_logic_vector(wordSize-1 downto 0);
            q1, q2       : out std_logic_vector(wordSize-1 downto 0)
        );
    end component;

    component signExtend is
        port(
            Instr_D  : in  std_logic_vector(31 downto 7); 
            ImmSrc_D : in  std_logic_vector(1 downto 0);
            ImmExt_D : out std_logic_vector(31 downto 0) 
        );
    end component;

    component registrador_universal is
        generic (
            word_size: positive := 4
        );
        port (
            clock, clear, set, enable : in std_logic;
            control                   : in std_logic_vector(1 downto 0);
            serial_input              : in std_logic;
            parallel_input            : in std_logic_vector(word_size-1 downto 0);
            parallel_output           : out std_logic_vector(word_size-1 downto 0)
        );
    end component;

    component hazard_unit is
        port(
            Rs1_D          : in std_logic_vector(4 downto 0);
            Rs1_E          : in std_logic_vector(4 downto 0);
            Rs2_D          : in std_logic_vector(4 downto 0);
            Rs2_E          : in std_logic_vector(4 downto 0);
            Rd_E           : in std_logic_vector(4 downto 0);
            Rd_M           : in std_logic_vector(4 downto 0);
            Rd_W           : in std_logic_vector(4 downto 0);
            ResultSrc_E_b0 : in std_logic;
            RegWrite_M     : in std_logic;
            RegWrite_W     : in std_logic;
            PCSrc_E        : in std_logic;
            ForwardA_E     : out std_logic_vector(1 downto 0);
            ForwardB_E     : out std_logic_vector(1 downto 0);
            Stall_F        : out std_logic;
            Stall_D        : out std_logic;
            Flush_D        : out std_logic;
            Flush_E        : out std_logic   
        );
    end component;

    signal not_clock                                             : std_logic;
    signal PC_F_line                                             : std_logic_vector(31 downto 0);
    signal PC_F, PC_D, PC_E                                      : std_logic_vector(31 downto 0);
    signal PCPlus4_F, PCPlus4_D, PCPlus4_E, PCPlus4_M, PCPlus4_W : std_logic_vector(31 downto 0);
    signal Instr_F, Instr_D                                      : std_logic_vector(31 downto 0);
    signal RD1_E, RD1_D                                          : std_logic_vector(31 downto 0);
    signal RD2_E, RD2_D                                          : std_logic_vector(31 downto 0);
    signal WriteData_E, WriteData_M                              : std_logic_vector(31 downto 0);
    signal ALUResult_E, ALUResult_M, ALUResult_W                 : std_logic_vector(31 downto 0);
    signal ReadData_M, ReadData_W                                : std_logic_vector(31 downto 0);
    signal Result_W                                              : std_logic_vector(31 downto 0);
    signal SrcA_E                                                : std_logic_vector(31 downto 0);
    signal SrcB_E                                                : std_logic_vector(31 downto 0);
    signal PCTarget_E                                            : std_logic_vector(31 downto 0);
	signal ImmExt_D, ImmExt_E                                    : std_logic_vector(31 downto 0);
    signal Rd_D, Rd_E, Rd_M, Rd_W                                : std_logic_vector(4 downto 0);
    signal Zero_E                                                : std_logic;
    signal PCSrc_E                                               : std_logic;
    signal RegWrite_E, RegWrite_M, RegWrite_W                    : std_logic;
    signal ResultSrc_E, ResultSrc_M, ResultSrc_W                 : std_logic_vector(1 downto 0);
    signal MemWrite_E, MemWrite_M                                : std_logic;
    signal Jump_E                                                : std_logic;
    signal Branch_E                                              : std_logic;
    signal ALUControl_E                                          : std_logic_vector(2 downto 0);
    signal ALUSrc_E                                              : std_logic;
    signal ForwardA_E, ForwardB_E                                : std_logic_vector(1 downto 0);
    signal Rs1_D, Rs1_E                                          : std_logic_vector(4 downto 0);
    signal Rs2_D, Rs2_E                                          : std_logic_vector(4 downto 0);
    signal HazardSrcB_E                                          : std_logic_vector(31 downto 0);
    signal Flush_D, Flush_E                                      : std_logic;
    signal Stall_F, Stall_D                                      : std_logic;
    signal EnableRegisterFetchToDecode                           : std_logic;
    signal ClearRegisterFetchToDecode                            : std_logic;
    signal EnableRegisterProgramCounter                          : std_logic;
    signal ClearRegisterDecodeToExecute                          : std_logic;

    constant FourVector                                          : std_logic_vector(31 downto 0) := "00000000000000000000000000000100";

begin
    
    --Registradores do pipeline
    EnableRegisterFetchToDecode  <= not Stall_D;
    EnableRegisterProgramCounter <= not Stall_F;
    ClearRegisterFetchToDecode   <= Flush_D;
    ClearRegisterDecodeToExecute <= Flush_E or reset;

    -- registradores IF/ID
    REG_IF_ID_Instr: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => EnableRegisterFetchToDecode,
            control         => "11",
            serial_input    => '0',
            parallel_input  => Instr_F,
            parallel_output => Instr_D
        );

    REG_IF_ID_PC: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => EnableRegisterFetchToDecode,
            control         => "11",
            serial_input    => '0',
            parallel_input  => PC_F,
            parallel_output => PC_D
        );

    REG_IF_ID_PCPlus4: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => EnableRegisterFetchToDecode,
            control         => "11",
            serial_input    => '0',
            parallel_input  => PCPlus4_F,
            parallel_output => PCPlus4_D
        );

    --registrador ID/EX
    REG_ID_EX_RD1: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => ClearRegisterDecodeToExecute, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => RD1_D,
            parallel_output => RD1_E
        );

    REG_ID_EX_RD2: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => ClearRegisterDecodeToExecute, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => RD2_D,
            parallel_output => RD2_E
        );

    REG_ID_EX_PC: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => ClearRegisterDecodeToExecute, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => PC_D,
            parallel_output => PC_E
        );

    REG_ID_EX_ImmExt: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => ClearRegisterDecodeToExecute, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => ImmExt_D,
            parallel_output => ImmExt_E
        );

    REG_ID_EX_PCPlus4: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => ClearRegisterDecodeToExecute, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => PCPlus4_D,
            parallel_output => PCPlus4_E
        );

    REG_ID_EX_Rd: registrador_universal
        generic map(word_size => 5)
        port map(
            clock           => clock, 
            clear           => ClearRegisterDecodeToExecute, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => Rd_D,
            parallel_output => Rd_E
        );
        
    REG_ID_EX_ResultSrc: registrador_universal
        generic map(word_size => 2)
        port map(
            clock           => clock, 
            clear           => ClearRegisterDecodeToExecute, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => ResultSrc_D,
            parallel_output => ResultSrc_E
        );

    REG_ID_EX_Rs1: registrador_universal
        generic map(word_size => 5)
        port map(
            clock           => clock, 
            clear           => ClearRegisterDecodeToExecute, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => Rs1_D,
            parallel_output => Rs1_E
        );

    REG_ID_EX_Rs2: registrador_universal
        generic map(word_size => 5)
        port map(
            clock           => clock, 
            clear           => ClearRegisterDecodeToExecute, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => Rs2_D,
            parallel_output => Rs2_E
        );

    --registradores EX/MEM
    REG_EX_MEM_ALUResult: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => ALUResult_E,
            parallel_output => ALUResult_M
        );

    REG_EX_MEM_WriteData: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => WriteData_E,
            parallel_output => WriteData_M
        );

    REG_EX_MEM_PCPlus4: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => PCPlus4_E,
            parallel_output => PCPlus4_M
        );

    REG_EX_MEM_Rd: registrador_universal
        generic map(word_size => 5)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => Rd_E,
            parallel_output => Rd_M
        );

    REG_EX_MEM_ResultSrc: registrador_universal
        generic map(word_size => 2)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => ResultSrc_E,
            parallel_output => ResultSrc_M
        );

    --registradores MEM/WB
    REG_MEM_WB_ALUResult: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => ALUResult_M,
            parallel_output => ALUResult_W
        );

    REG_MEM_WB_ReadData: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => ReadData_M,
            parallel_output => ReadData_W
        );

    REG_MEM_WB_PCPlus4: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => PCPlus4_M,
            parallel_output => PCPlus4_W
        );

    REG_MEM_WB_Rd: registrador_universal
        generic map(word_size => 5)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => Rd_M,
            parallel_output => Rd_W
        );


    REG_MEM_WB_ResultSrc: registrador_universal
        generic map(word_size => 2)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => ResultSrc_M,
            parallel_output => ResultSrc_W
        );

    -- Registradores de sinais de controle
    CONTROL_UNIT_REGISTER_ID_EX: process(clock, ClearRegisterDecodeToExecute)
    begin
        if ClearRegisterDecodeToExecute = '1' then
            RegWrite_E   <= '0';
            ResultSrc_E  <= "00";
            MemWrite_E   <= '0';
            Jump_E       <= '0';
            Branch_E     <= '0';
            ALUControl_E <= "000";
            ALUSrc_E     <= '0';
        elsif clock'event and clock = '1' then
            RegWrite_E   <= RegWrite_D;
            ResultSrc_E  <= ResultSrc_D;
            MemWrite_E   <= MemWrite_D;
            Jump_E       <= Jump_D;
            Branch_E     <= Branch_D;
            ALUControl_E <= ALUControl_D;
            ALUSrc_E     <= ALUSrc_D;
        end if;
    end process;

    CONTROL_UNIT_REGISTER_EX_MEM: process(clock, reset)
    begin
        if reset = '0' then
            RegWrite_M   <= '0';
            ResultSrc_M  <= "00";
            MemWrite_M   <= '0';
        elsif clock'event and clock = '1' then
            RegWrite_M   <= RegWrite_E;
            ResultSrc_M  <= ResultSrc_E;
            MemWrite_M   <= MemWrite_E;
        end if;
    end process;

    CONTROL_UNIT_REGISTER_MEM_WB: process(clock, reset)
    begin
        if reset = '0' then
            RegWrite_W   <= '0';
            ResultSrc_W  <= "00";
        elsif clock'event and clock = '1' then
            RegWrite_W   <= RegWrite_M;
            ResultSrc_W  <= ResultSrc_M;
        end if;
    end process;

    -- MUX 2x1
    PC_F_line <= PCPlus4_F when PCSrc_E = '0' else PCTarget_E;

    -- PC Register
    PC: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock,
            clear           => reset, 
            set             => '0', 
            enable          => EnableRegisterProgramCounter, 
            control         => "11", 
            serial_input    => '0', 
            parallel_input  => PC_F_line, 
            parallel_output => PC_F
        );

    -- Next Instruction Counter
    NEXT_INSTRUCTION: ALU
        generic map (
            word_size => 32
        )
        port map(
            A          => PC_F,
            B          => FourVector,
            ALUControl => "000",
            Result     => PCPlus4_F,
            Overflow   => open,
            CarryOut   => open,
            Negative   => open,
            Zero       => open
        );

    -- Instruction Memory Interface
    IM_Addr     <= PC_F;
    Instr_F     <= IM_ReadData;
    
    -- banco de registradores
    not_clock <= not clock;

    rf: regfile
        generic map(
            regn     => 32,
            wordSize => 32
        )
        port map(
            clock    => not_clock,
            reset    => reset,
            regWrite => RegWrite_W,
            rr1      => Instr_D(19 downto 15), 
            rr2      => Instr_D(24 downto 20),
            wr       => Rd_W, 
            d        => Result_W,
            q1       => RD1_D, 
            q2       => RD2_D 
        );

    -- sign extender
    SIGN_EXT: signExtend
    port map(
        Instr_D  => Instr_D(31 downto 7),
        ImmSrc_D => ImmSrc_D,
        ImmExt_D => ImmExt_D
    );

    -- Hazard Forwarding MUX 3x1
    SrcA_E <= RD1_E       when ForwardA_E = "00" else
              Result_W    when ForwardA_E = "01" else
              ALUResult_M when ForwardA_E = "10";

    -- Hazard Forwarding MUX 3x1
    HazardSrcB_E <= RD2_E       when ForwardB_E = "00" else
                    Result_W    when ForwardA_E = "01" else
                    ALUResult_M when ForwardA_E = "10";

    -- MUX 2x1
    SrcB_E <= HazardSrcB_E when ALUSrc_E = '0' else ImmExt_E;

    -- Branch ALU
    BRANCH_ALU: ALU
        generic map (
            word_size => 32
        )
        port map (
            A          => PC_E,
            B          => ImmExt_E,
            ALUControl => "000",
            Result     => PCTarget_E,
            Overflow   => open,
            CarryOut   => open,
            Negative   => open,
            Zero       => open
        );

    -- General ALU
    GENERAL_ALU: ALU
    generic map (
        word_size => 32
    )
    port map (
        A          => SrcA_E,
        B          => SrcB_E,
        ALUControl => ALUControl_E,
        Result     => ALUResult_E,
        Overflow   => open,
        CarryOut   => open,
        Negative   => open,
        Zero       => Zero_E
    );

    -- Data Memory Interface
    ReadData_M     <= DM_ReadData;
    DM_Addr        <= ALUResult_M;
    DM_WriteData   <= WriteData_M;
    DM_WriteEnable <= MemWrite_M;

    -- MUX 3x1
    Result_W <= ALUResult_W when ResultSrc_W = "00" else
                ReadData_W  when ResultSrc_W = "01" else
                PCPlus4_W   when ResultSrc_W = "10" else
                "00000000000000000000000000000000";

    -- Connecting signals
    WriteData_E <= HazardSrcB_E;
    Rd_D        <= Instr_D(11 downto 7);
    Rs1_D       <= Instr_D(19 downto 15);
    Rs2_D       <= Instr_D(24 downto 20);

    -- Output logic
    opcode <= Instr_D(6 downto 0);
    funct3 <= Instr_D(14 downto 12);
    funct7 <= Instr_D(30);

    PCSrc_E <= Jump_E or (Zero_E and Branch_E);

    -- Hazard Unit
    HAZARD: hazard_unit
    port map (
        Rs1_D          => Rs1_D,
        Rs1_E          => Rs1_E,
        Rs2_D          => Rs2_D,
        Rs2_E          => Rs2_E,
        Rd_E           => Rd_E,
        Rd_M           => Rd_M,
        Rd_W           => Rd_W,
        ResultSrc_E_b0 => ResultSrc_E(0),
        RegWrite_M     => RegWrite_M,
        RegWrite_W     => RegWrite_W,
        PCSrc_E        => PCSrc_E,
        ForwardA_E     => ForwardA_E,
        ForwardB_E     => ForwardB_E,
        Stall_F        => Stall_F,
        Stall_D        => Stall_D,
        Flush_D        => Flush_D,
        Flush_E        => Flush_E
    );
   
end PoliLeg_FD ; -- PoliLeg_FD