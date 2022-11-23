--Top level component
entity polilegsc is
    port(
        clock, reset : in bit;
        dmem_addr : out bit_vector(63 downto 0);
        dmem_dati : out bit_vector(63 downto 0);
        dmem_dato : in  bit_vector(63 downto 0);
        dmem_we   : out bit;
        imem_addr : out bit_vector(63 downto 0);
        imem_data : in  bit_vector(31 downto 0)
    );
end entity;

architecture PoliLeg of polilegsc is

    component datapath is 
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
    end component;

    component controlunit is
        port(
            -- To Datapath
            reg2loc      : out bit;
            uncondBranch : out bit;
            branch       : out bit;
            memRead      : out bit;
            memToReg     : out bit;
            aluOp        : out bit_vector(1 downto 0);
            memWrite     : out bit;
            aluSrc       : out bit;
            regWrite     : out bit;
            -- From Datapath
            opcode       : in bit_vector(10 downto 0)
        );
    end component;

    component alucontrol is
        port(
            aluop   : in bit_vector(1 downto 0);
            opcode  : in bit_vector(10 downto 0);
            aluCtrl : out bit_vector(3 downto 0)
        );
    end component;

    signal r2l, ub, b, mtr, mw, mr, alus, rw : bit;
    signal aluo                              : bit_vector(1 downto 0);
    signal opc                               : bit_vector(10 downto 0);
    signal aluc                              : bit_vector(3 downto 0);
    signal z                                 : bit;
    signal pcs                               : bit;

    signal imAddr, dmAddr, dmIn, dmOut : bit_vector(63 downto 0);
    signal imOut                       : bit_vector(31 downto 0);

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