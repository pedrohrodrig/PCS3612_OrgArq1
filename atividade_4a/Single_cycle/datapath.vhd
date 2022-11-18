--Fluxo de dados
library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

entity datapath is
    port(
        -- Common
        clock : in bit;
        reset : in bit;

        -- From Control Unit
        reg2loc : in bit;
        pcsrc : in bit;
        memToReg : in bit;
        aluCtrl : in bit_vector(3 downto 0);
        aluSrc : in bit;
        regWrite : in bit;

        -- To Control Unit
        opcode : out bit_vector(10 downto 0);
        zero : out bit;

        -- IM Interface
        imAddr : out bit_vector(63 downto 0);
        imOut : in bit_vector(31 downto 0);

        -- DM Interface
        dmAddr : out bit_vector(63 downto 0);
        dmIn : out bit_vector(63 downto 0);
        dmOut : in bit_vector(63 downto 0)
    );
end entity datapath;

architecture PoliLeg_FD of datapath is

    component alu is
        generic(
            size : natural := 64
        );
        port(
            A, B : in  bit_vector(size-1 downto 0); -- inputs
            F    : out bit_vector(size-1 downto 0); -- output
            S    : in  bit_vector(3 downto 0); -- op selection
            Z    : out bit; -- zero flag
            Ov   : out bit; -- overflow flag
            Co   : out bit -- carry out
        );
    end component;

    component regfile is
        generic(
            regn : natural := 32; -- numero de registradores
            wordSize : natural := 64
        );
        port(
            clock: in bit;
            reset : in bit;
            regWrite : in bit;
            rr1, rr2, wr : in bit_vector(natural(ceil(log2(real(regn))))-1 downto 0); -- bit_vector(log2(regn)-1 downto 0)
            d : in bit_vector(wordSize-1 downto 0);
            q1, q2 : out bit_vector(wordSize-1 downto 0)
        );
    end component;

    component signExtend is
        port(
            i: in  bit_vector(31 downto 0); -- input
            o: out bit_vector(63 downto 0) -- output
        );
    end component;

    component registrador_universal is
        generic (
            word_size: positive := 4
        );
        port (
            clock, clear, set, enable: in bit;
            control: in bit_vector(1 downto 0);
            serial_input: in bit;
            parallel_input: in bit_vector(word_size-1 downto 0);
            parallel_output: out bit_vector(word_size-1 downto 0)
        );
    end component;

    signal PCNextOrdInst, PCNextInst, PCBranchInst : bit_vector(63 downto 0);
    signal imD1, imD2 : bit_vector(63 downto 0);
    signal dmToIm : bit_vector(63 downto 0);
    signal MUXImOut : bit_vector(4 downto 0);
    signal imD2OrExtAddr : bit_vector(63 downto 0);
    signal dmAddr_o, imAddr_o, dmIn_o: bit_vector(63 downto 0);
    signal imOut_o : bit_vector(31 downto 0);
    signal dmOut_o : bit_vector(63 downto 0);
    signal extAddr, shiftedExtAddr : bit_vector(63 downto 0);

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
    imAddr <= imAddr_o;
    dmAddr <= dmAddr_o;

    -- somador da proxima instrucao ordenada
    pcNOrdInst: alu 
    generic map(64)
    port map(imAddr_o, "0000000000000000000000000000000000000000000000000000000000000100", PCNextOrdInst, "0010", open, open, open);

    -- registrador que guarda a proxima instrucao
    pc: registrador_universal
    generic map(64)
    port map(clock, reset, '0', '1', "11", '0', PCNextInst, imAddr_o);
    
    -- MUX seleciona prox instrucao ordenada ou com branch
    PCNextInst <= PCNextOrdInst when pcsrc = '0' else PCBranchInst;

    -- MUX seleciona qual parte da instrucao entra no banco de registradores
    MUXImOut <= imOut_o(20 downto 16) when reg2loc = '0' else imOut_o(4 downto 0);

    -- banco de registradores
    rf: regfile
    generic map(32, 64)
    port map(clock, reset, regWrite, imOut_o(9 downto 5), MUXImOut, imOut_o(4 downto 0), dmToIm, imD1, imD2);

    -- signExtend
    se: signExtend
    port map(imOut_o, extAddr);

    -- MUX do segundo operando da ALU multioperacional
    imD2OrExtAddr <= imD2 when aluSrc = '0' else extAddr;

    -- alu multioperacional
    opAlu : alu
    generic map(64)
    port map(imD1, imD2OrExtAddr, dmAddr_o, aluCtrl, zero, open, open);

    -- MUX seleciona o que sera escrito no regfile
    dmToIm <= dmAddr_o when memToReg = '0' else dmOut_o;

    -- shift left 2
    shiftedExtAddr <= extAddr(61 downto 0) & "00";

    -- alu que define a proxima instrucao dada pelo branch
    brAlu : alu
    generic map(64)
    port map(imAddr_o, shiftedExtAddr, PCBranchInst, "0010", open, open, open);

    opcode <= imOut_o(31 downto 21);
	 
	dmIn_o <= imD2;

end PoliLeg_FD ; -- PoliLeg_FD