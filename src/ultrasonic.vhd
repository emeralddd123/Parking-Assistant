LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.all;
USE ieee.numeric_std;
ENTITY ultrasonic IS
    PORT (
        clk : IN STD_LOGIC;
        pulse : IN STD_LOGIC; -- echo
        triggerOut : OUT STD_LOGIC; -- trigger out
        distanceOut : OUT INTEGER RANGE 0 TO 400); -- Adjust range as needed
END ENTITY;

ARCHITECTURE behaviour OF ultrasonic IS
    COMPONENT counter IS
        GENERIC (n : POSITIVE := 10);
        PORT (
            clk : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            reset : IN STD_LOGIC; -- active low
            counter_output : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT trigger_generator IS
        PORT (
            clk : IN STD_LOGIC;
            trigg : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL pulse_width : STD_LOGIC_VECTOR(21 DOWNTO 0);
    SIGNAL trigg : STD_LOGIC;
    SIGNAL distance_cm : INTEGER;

BEGIN
    counter_echo_pulse :
    counter GENERIC MAP(22) PORT MAP(clk, pulse, NOT(trigg), pulse_width);

    trigger_generation :
    trigger_generator PORT MAP(clk, trigg);

    distance_cm <= conv_integer(unsigned(pulse_width)) / 58; -- Speed of sound is ~34300 cm/s

    triggerOut <= trigg;
    distanceOut <= distance_cm;
END ARCHITECTURE;