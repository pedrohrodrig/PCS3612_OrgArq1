library ieee;
use ieee.std_logic_1164.all;

--Top level component
entity polilegsc is
    port(
        clock, reset : in std_logic;
        dmem_addr : out std_logic_vector(63 downto 0);
        dmem_dati : out std_logic_vector(63 downto 0);
        dmem_dato : in  std_logic_vector(63 downto 0);
        dmem_we   : out std_logic;
        imem_addr : out std_logic_vector(63 downto 0);
        imem_data : in  std_logic_vector(31 downto 0)
    );
end entity;

architecture PoliLeg of polilegsc is

    component datapath is 
        port(
            -- Common
            clock : in std_logic;
            reset : in std_logic;

            -- From Control Unit
            reg2loc : in std_logic;
            pcsrc : in std_logic;
            memToReg : in std_logic;
            aluCtrl : in std_logic_vector(3 downto 0);
            aluSrc : in std_logic;
            regWrite : in std_logic;

            -- To Control Unit
            opcode : out std_logic_vector(10 downto 0);
            zero : out std_logic;

            -- IM Interface
            imAddr : out std_logic_vector(63 downto 0);
            imOut : in std_logic_vector(31 downto 0);

            -- DM Interface
            dmAddr : out std_logic_vector(63 downto 0);
            dmIn : out std_logic_vector(63 downto 0);
            dmOut : in std_logic_vector(63 downto 0)
        );
    end component;

    component controlunit is
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
    end component;

    component alucontrol is
        port(
            aluop   : in std_logic_vector(1 downto 0);
            opcode  : in std_logic_vector(10 downto 0);
            aluCtrl : out std_logic_vector(3 downto 0)
        );
    end component;

    signal r2l, ub, b, mtr, mw, mr, alus, rw : std_logic;
    signal aluo                              : std_logic_vector(1 downto 0);
    signal opc                               : std_logic_vector(10 downto 0);
    signal aluc                              : std_logic_vector(3 downto 0);
    signal z                                 : std_logic;
    signal pcs                               : std_logic;

    signal imAddr, dmAddr, dmIn, dmOut : std_logic_vector(63 downto 0);
    signal imOut                       : std_logic_vector(31 downto 0);

begin

    -- maracutaia para resultado dar certo e manter a carta de tempo correta
    we : process(clock)
    begin
        if clock'event and clock = '1' then
            dmem_we <= mw;
        end if;
    end process;

    pcs       <= ub or (z and b);
    imem_addr <= imAddr;
    imOut     <= imem_data; -- in
    dmem_addr <= dmAddr;
    dmem_dati <= dmIn;
    dmOut     <= dmem_dato; -- in

    fd : datapath
    port map(clock, reset, r2l, pcs, mtr, aluc, alus, rw, opc, z, imAddr, imOut, dmAddr, dmIn, dmOut);

    ucg : controlunit
    port map(r2l, ub, b, mr, mtr, aluo, mw, alus, rw, opc);

    ucalu : alucontrol
    port map(aluo, opc, aluc);

end PoliLeg ; -- PoliLeg