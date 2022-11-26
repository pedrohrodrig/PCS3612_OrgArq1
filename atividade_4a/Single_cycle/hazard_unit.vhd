library ieee;
use ieee.std_logic_1164.all;

entity hazard_unit is
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
end entity;

architecture hazard_unit_behavioral of hazard_unit is

    signal lwStall : std_logic;
    
begin
    
    ForwardA_E <= "10" when (Rs1_E = Rd_M and RegWrite_M = '1' and Rs1_E /= '0') else
                  "01" when (Rs1_E = Rd_W and RegWrite_W = '1' and Rs1_E /= '0') else
                  "00";

    ForwardB_E <= "10" when (Rs2_E = Rd_M and RegWrite_M = '1' and Rs2_E /= '0') else
                  "01" when (Rs2_E = Rd_W and RegWrite_W = '1' and Rs2_E /= '0') else
                  "00";

    lwStall <= '1' when ResultSrc_E_b0 and ((Rs1_D = Rd_E) or (Rs2_D = Rd_E)) else '0';

    Stall_F <= lwStall;
    Stall_D <= lwStall;
    Flush_D <= PCSrc_E;
    Flush_E <= lwStall or PCSrc_E;
    
end architecture hazard_unit_behavioral;