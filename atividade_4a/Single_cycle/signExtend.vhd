--SignExtend
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signExtend is
    port(
        i : in  std_logic_vector(31 downto 0); -- input
        o : out std_logic_vector(63 downto 0) -- output
    );
end signExtend;

architecture behavioral_se of signExtend is

    signal opcode     : std_logic_vector(5 downto 0);
    signal addressD   : std_logic_vector(8 downto 0);
    signal addressB   : std_logic_vector(25 downto 0);
    signal addressCBZ : std_logic_vector(18 downto 0);

    -- OPCODES
    -- B : 000101
    -- CBZ : 101101
    -- LDUR : 11111000010
    -- STUR : 11111000000

begin

    opcode <= i(31 downto 26);

    addressD   <= i(20 downto 12); --when (opcode(10 downto 0) = "11111000010" or opcode(10 downto 0) = "11111000000") else
    addressB   <= i(25 downto 0);
    addressCBZ <= i(23 downto 5);

    o <= std_logic_vector(resize(signed(addressD), 64))   when (opcode = "111110") else
         std_logic_vector(resize(signed(addressB), 64))   when (opcode = "000101") else
         std_logic_vector(resize(signed(addressCBZ), 64)) when (opcode = "101101") else
         "0000000000000000000000000000000000000000000000000000000000000000";


end behavioral_se ; -- behavioral