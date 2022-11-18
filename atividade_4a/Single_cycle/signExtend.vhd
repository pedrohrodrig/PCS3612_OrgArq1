--SignExtend
library ieee;
use ieee.numeric_bit.all;

entity signExtend is
    port(
        i: in  bit_vector(31 downto 0); -- input
        o: out bit_vector(63 downto 0) -- output
    );
end signExtend;

architecture behavioral_se of signExtend is

    signal opcode : bit_vector(5 downto 0);
    signal addressD : bit_vector(8 downto 0);
    signal addressB : bit_vector(25 downto 0);
    signal addressCBZ : bit_vector(18 downto 0);

    -- OPCODES
    -- B : 000101
    -- CBZ : 101101
    -- LDUR : 11111000010
    -- STUR : 11111000000

begin

    opcode <= i(31 downto 26);

    addressD <= i(20 downto 12); --when (opcode(10 downto 0) = "11111000010" or opcode(10 downto 0) = "11111000000") else
    addressB <= i(25 downto 0);
    addressCBZ <= i(23 downto 5);

    o <=
        bit_vector(resize(signed(addressD), 64))   when (opcode = "111110") else
        bit_vector(resize(signed(addressB), 64))   when (opcode = "000101") else
        bit_vector(resize(signed(addressCBZ), 64)) when (opcode = "101101") else
        "0000000000000000000000000000000000000000000000000000000000000000";


end behavioral_se ; -- behavioral