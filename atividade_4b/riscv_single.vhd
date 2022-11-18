library ieee;
use ieee.std_logic_1164.all;

entity riscv_single is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;
        instr      : in  std_logic_vector(31 downto 0);
        read_data  : in  std_logic_vector(31 downto 0);
        mem_write  : out std_logic;
        pc         : out std_logic_vector(31 downto 0);
        alu_result : out std_logic_vector(31 downto 0);
        write_data : out std_logic_vector(31 downto 0)
    );
end entity;

architecture riscv_single_behavioral of riscv_single is
    
begin
    
    
    
end architecture riscv_single_behavioral;