LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY parkingAssistant IS
    PORT (
        clk : IN STD_LOGIC;
        pulse : IN STD_LOGIC_VECTOR(2 DOWNTO 0); --echo back from ultrasonic
        triggerOut : OUT STD_LOGIC_VECTOR(2 DOWNTO 0); --ultrasonic trigger
        red, grn, blu : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        hsync, vsync : OUT STD_LOGIC
    );
END ENTITY parkingAssistant;

ARCHITECTURE helper OF parkingAssistant IS

    --3 ultrasonic component (the inputs)
    COMPONENT three_ultrasonic IS
        PORT (
            clk : IN STD_LOGIC;
            pulse : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            triggerOut : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            rear_left, rear_center, rear_right : OUT INTEGER RANGE 0 TO 400);
    END COMPONENT;

    --vga component (output)
    COMPONENT vga_display IS
        PORT (
            clk : IN STD_LOGIC;
            red, grn, blu : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            hsync, vsync : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL rear_left, rear_center, rear_right : INTEGER RANGE 0 TO 400;
    SIGNAL s_pulse : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL s_triggerOut : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL red, grn, blu : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL hsync, vsync : STD_LOGIC;
BEGIN
    s_pulse <= pulse;
    triggerOut <= s_triggerOut;
    --  s_red <= red;
    --  grn <= s_grn;
    --  blu <= s_blu;
    --  vsync <= s_vsync;
    --  hsync <= s_hsync;
    --port mapping
    ultrasonic_mapping : three_ultrasonic PORT MAP(clk, s_pulse, s_triggerOut, rear_left, rear_center, rear_right);
    display_mapping : vga_display PORT MAP(
        clk, red, grn, blu,
        hsync, vsync,
        rear_left, rear_center,
        rear_right);

    --some logic
    -- main : process( rear_left, rear_center, rear_right )
    -- begin

    -- end process ; -- main

END ARCHITECTURE helper;