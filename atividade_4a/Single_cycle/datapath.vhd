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
        reg2loc  : in std_logic;
        pcsrc    : in std_logic;
        memToReg : in std_logic;
        aluCtrl  : in std_logic_vector(3 downto 0);
        aluSrc   : in std_logic;
        regWrite : in std_logic;

        -- To Control Unit
        opcode : out std_logic_vector(10 downto 0);
        zero   : out std_logic;

        -- IM Interface
        imAddr : out std_logic_vector(63 downto 0);
        imOut  : in std_logic_vector(31 downto 0); --Instrução coletada da memória de intruções

        -- DM Interface
        dmAddr : out std_logic_vector(63 downto 0);
        dmIn   : out std_logic_vector(63 downto 0);
        dmOut  : in std_logic_vector(63 downto 0)
    );
end entity datapath;

architecture PoliLeg_FD of datapath is

    component alu is
        generic(
            size : natural := 64
        );
        port(
            A, B : in  std_logic_vector(size-1 downto 0); -- inputs
            F    : out std_logic_vector(size-1 downto 0); -- output
            S    : in  std_logic_vector(3 downto 0); -- op selection
            Z    : out std_logic; -- zero flag
            Ov   : out std_logic; -- overflow flag
            Co   : out std_logic -- carry out
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
            i: in  std_logic_vector(31 downto 0); -- input
            o: out std_logic_vector(63 downto 0) -- output
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

    signal PCNextInst, PCBranchInst                : std_logic_vector(63 downto 0);
    signal imD1, imD2                              : std_logic_vector(63 downto 0);
    signal dmToIm                                  : std_logic_vector(63 downto 0);
    signal MUXImOut                                : std_logic_vector(4 downto 0);
    signal imD2OrExtAddr                           : std_logic_vector(63 downto 0);
    signal dmAddr_o, dmIn_o                        : std_logic_vector(63 downto 0);
    signal imOut_o                                 : std_logic_vector(31 downto 0);
    signal dmOut_o                                 : std_logic_vector(63 downto 0);
    signal extAddr, shiftedExtAddr                 : std_logic_vector(63 downto 0);
    signal out_IFID, in_IFID                       : std_logic_vector(63 downto 0);
    signal out_IDEX, in_IDEX                       : std_logic_vector(63 downto 0);
    signal out_EXMEM, in_EXMEM                     : std_logic_vector(63 downto 0);
    signal out_MEMWB, in_MEMWB                     : std_logic_vector(63 downto 0);
    signal not_clock                               : std_logic;
    signal PC_F, PC_D                              : std_logic_vector(31 downto 0);
    signal PCPlus4_F, PCPlus4_D                    : std_logic_vector(31 downto 0);
    signal Instr_F, Instr_D                        : std_logic_vector(31 downto 0);

begin

    --  final da operação é zero
    fd: process(clock)
    begin
        if rising_edge(clock) then
            dmIn <= dmIn_o;
        end if;
    end process;

    imOut_o <= imOut;
    dmOut_o <= dmOut;
    imAddr  <= PC_F;
    dmAddr  <= dmAddr_o;

    --Entradas dos registradores do pipeline
    --Preenchendo com 0s o que ainda não tenho certeza de que deve entrar nos registradores. 
    in_IFID <= imOut & "00000000000000000000000000000000";
    in_IDEX <= extAddr & imD1 & imD2 & "0000000000000000000000000000000000000000000000000000000000000000";
    
    --Registradores do pipeline

    not_clock <= not clock;

    --registradores IF/ID
    REG_IF_ID_Instr: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
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
            enable          => '1',
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
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => PCPlus4_F,
            parallel_output => PCPlus4_D
        );

    --registrador ID/EX
    --Saidas: 
            --Entrada da ULA (rd1)
            --Entrada do MUX da ULA (rd2)
            --Entrada do somador (imm)
            --Entrada do mux (imm)
            --Entrada do somador (PCatual)
    REG_ID_EX_RD1: registrador_universal
        generic map(word_size => 32)
        port map(
            clock           => clock, 
            clear           => reset, 
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
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => RD2_D,
            parallel_output => RD2_E
        );

    

    --registrador EX/MEM
    --Entradas: 
            --Resultado do somador
            --Zero 
            --Resultado da ULA
            --(rd2)
    --Saídas:
            --Entrada do MUX do PC
            --Zero 
            --Endereço da memória de dados
            --Write data
    REG_EX_MEM: registrador_universal
        generic map(word_size => 64)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => in_EXMEM,
            parallel_output => out_EXMEM
        );

    --registrador MEM/WB
    --Entradas:
            --Read Data
            --Endereço da memória de dados
    --Saídas:
            --Ambas as entradas num MUX que alimenta o Write Data

    REG_MEM_WB: registrador_universal
        generic map(word_size => 64)
        port map(
            clock           => clock, 
            clear           => reset, 
            set             => '0', 
            enable          => '1',
            control         => "11",
            serial_input    => '0',
            parallel_input  => in_MEMWB,
            parallel_output => out_MEMWB
        );

    -- somador da proxima instrucao ordenada
    pcNOrdInst: alu 
        generic map(32)
        port map(
            PC_F, 
            "00000000000000000000000000000100", 
            PCPlus4_F, 
            "0010", 
            open, 
            open, 
            open
        );

    -- registrador que guarda a proxima instrucao
    pc: registrador_universal
        generic map(64)
        port map(
            clock,
            reset, 
            '0', 
            '1', 
            "11", 
            '0', 
            PCNextInst, 
            PC_F
        );
    
    -- MUX seleciona prox instrucao ordenada ou com branch
    PCNextInst <= PCPlus4_F when pcsrc = '0' else PCBranchInst;

    -- MUX seleciona qual parte da instrucao entra no banco de registradores
    MUXImOut <= imOut_o(20 downto 16) when reg2loc = '0' else imOut_o(4 downto 0);

    -- banco de registradores
    rf: regfile
        generic map(
            32,
            64
        )
        port map(
            not_clock,
            reset,
            regWrite,
            imOut_o(9 downto 5), --rr1
            MUXImOut,
            imOut_o(4 downto 0), --rr2 
            dmToIm, --wr
            imD1, --q1
            imD2 --q2
        );

    -- signExtend
    se: signExtend
        port map(
            out_IFID(63 downto 32),
            extAddr
        );

    -- MUX do segundo operando da ALU multioperacional
    imD2OrExtAddr <= imD2 when aluSrc = '0' else extAddr;

    -- alu multioperacional
    opAlu : alu
        generic map(64)
        port map(
            imD1,
            imD2OrExtAddr, 
            dmAddr_o, 
            aluCtrl, 
            zero, 
            open, 
            open
        );

    -- MUX seleciona o que sera escrito no regfile
    dmToIm <= dmAddr_o when memToReg = '0' else dmOut_o;

    -- shift left 2
    shiftedExtAddr <= extAddr(61 downto 0) & "00";

    -- alu que define a proxima instrucao dada pelo branch
    brAlu : alu
        generic map(64)
        port map(
            PC_F,
            shiftedExtAddr, 
            PCBranchInst, 
            "0010", 
            open, 
            open, 
            open
        );

    opcode <= imOut_o(31 downto 21);
	 
	dmIn_o <= imD2;

end PoliLeg_FD ; -- PoliLeg_FD