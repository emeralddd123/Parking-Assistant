LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
ENTITY counter IS
    GENERIC (n : POSITIVE := 10);
    PORT (
        clk : IN STD_LOGIC;
        enable : IN STD_LOGIC;
        reset : IN STD_LOGIC; -- active low
        counter_output : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0));
END ENTITY;
ARCHITECTURE behavioural OF counter IS
    SIGNAL count : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF (reset = '0') THEN
            count <= (OTHERS => '0');
        ELSIF (clk'event AND clk = '1') THEN
            IF (enable = '1') THEN
                count <= count + 1;
            END IF;
        END IF;
    END PROCESS;
    counter_output <= count;
END ARCHITECTURE;