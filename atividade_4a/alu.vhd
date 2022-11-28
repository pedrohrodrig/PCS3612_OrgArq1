library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is 
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
end entity;

architecture ALU_behavioral of ALU is
    
    signal B_or_notB        : std_logic_vector(word_size-1 downto 0);
    signal adderSrcB        : std_logic_vector(word_size-1 downto 0);
    signal resultAdder      : std_logic_vector(word_size downto 0);
    signal s_result         : std_logic_vector(word_size-1 downto 0);

    constant oneVector      : std_logic_vector(word_size-1 downto 0) := (0 => '1', others => '0');

begin
    
    -- MUX 2x1
    B_or_notB <= B when ALUControl(0) = '0' else (not B);
    adderSrcB <= B when ALUControl(0) = '1' else std_logic_vector(unsigned(B_or_notB) + unsigned(oneVector));

    -- Adder
    resultAdder <= std_logic_vector(unsigned(A(A'high) & A) + unsigned(adderSrcB(adderSrcB'high) & adderSrcB));
    
    -- MUX 5x1
    s_result <= resultAdder(word_size-1 downto 0)       when ALUControl = "000" or ALUControl = "001" else 
                (A and B)                               when ALUControl = "010"                       else
                (A or B)                                when ALUControl = "011"                       else
                '0' & resultAdder(word_size-2 downto 0) when ALUControl = "101"                       else
                (others => '0');
                
    -- Outputs
    CarryOut <= resultAdder(word_size) and (not ALUControl(1));
    Overflow <= (A(word_size-1) xnor B(word_size-1) xnor ALUControl(0)) and (A(word_size-1) xor resultAdder(word_size-1)) and (not ALUControl(1));
    Negative <= s_result(word_size-1);
    Zero     <= '1' when to_integer(unsigned(s_result)) = 0 else '0';
    Result   <= s_result;

end architecture ALU_behavioral;