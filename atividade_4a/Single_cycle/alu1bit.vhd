--Não tenho ideia do que é isso aqui 
library ieee;
use ieee.numeric_std.all;

entity alu1bit is
    port (
        a, b, less, cin             : in  std_logic;
        ainvert, binvert            : in  std_logic;
        operation                   : in  std_logic_vector(1 downto 0);
        result, cout, set, overflow : out std_logic
    );
end entity ;

architecture behav of alu1bit is
    
    signal au : std_logic;
    signal bu : std_logic;

begin

    au <= (not(a)) when ainvert = '1' else a;

    bu <= (not(b)) when binvert = '1' else b;

    result <= (au and bu)         when operation = "00" else
              (au or bu)          when operation = "01" else
              (au xor bu xor cin) when operation = "10" else
              (b);

    cout <= ((au and bu) or (au and cin) or (cin and bu));
        
    set <= (au xor bu xor cin);

    overflow <= ((au and bu) or (au and cin) or (cin and bu)) xor cin;

end behav;