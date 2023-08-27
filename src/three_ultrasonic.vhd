LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY three_ultrasonic IS
    PORT (
        clk : IN STD_LOGIC;
        pulse : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        triggerOut : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rear_left, rear_center, rear_right1 : OUT INTEGER RANGE 0 TO 400);
END ENTITY;
ARCHITECTURE behaviour OF three_ultrasonic IS
    COMPONENT ultrasonic IS
        PORT (
            clk : IN STD_LOGIC;
            pulse : IN STD_LOGIC; -- echo
            triggerOut : OUT STD_LOGIC; -- trigger out
            obstacle : OUT STD_LOGIC);
    END COMPONENT;
BEGIN
    ultrasonic_Left : ultrasonic PORT MAP(clk, pulse(0), triggerOut(0), ultrasonic_out(0));
    ultrasonic_Middle : ultrasonic PORT MAP(clk, pulse(1), triggerOut(1), ultrasonic_out(1));
    ultrasonic_Right : ultrasonic PORT MAP(clk, pulse(2), triggerOut(2), ultrasonic_out(2));
END ARCHITECTURE;