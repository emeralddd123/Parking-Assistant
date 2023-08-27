LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
ENTITY clkdiv IS
    PORT (
        clock_50 : IN STD_LOGIC;
        clr : IN STD_LOGIC;
        clock_q : OUT STD_LOGIC);
END ENTITY;
ARCHITECTURE behaviour OF clkdiv IS
    SIGNAL q : STD_LOGIC_VECTOR(23 DOWNTO 0);
BEGIN
    --clock divider
    PROCESS (clock_50, clr)
    BEGIN
        IF clr = '1' THEN
            q <= X"000000"; -- hex number
        ELSIF clock_50'event AND clock_50 = '1' THEN
            q <= q + 1;
        END IF;
    END PROCESS;
    clock_q <= q(6);
END ARCHITECTURE;