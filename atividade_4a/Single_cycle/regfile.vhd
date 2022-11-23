--Banco de Registradores
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use ieee.numeric_std.all;

entity regfile is
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
end regfile;

-- registrador 31: nao aceita escritas e retorna 0 quando lido
-- wr: dita qual registrador vai receber escrita, se regWrite for alto, se nao nada acontece
-- banco[wr]<=d sse regwrite=1 e rising_edge(clock)
-- leitura é assincrona: q1<=banco[rr1] e q2<=banco[rr2]

architecture behavior_regfile of regfile is

    type banco_t is array (0 to regn-1) of std_logic_vector(wordSize-1 downto 0);

    signal banco : banco_t;

begin

    --banco(regn-1) <= (others => '0');

    process(clock, reset, regWrite)

    begin
        if reset = '1' then
            for i in banco_t'range loop
                banco(i) <= (others => '0');
            end loop;
        elsif rising_edge(clock) and regWrite = '1' then
            if to_integer(unsigned(wr)) /= regn-1 then
                banco(to_integer(unsigned(wr))) <= d;
            end if;
        end if;
    end process;

    q1 <= banco(to_integer(unsigned(rr1)));
    q2 <= banco(to_integer(unsigned(rr2)));

end behavior_regfile ; -- behavior_regfile