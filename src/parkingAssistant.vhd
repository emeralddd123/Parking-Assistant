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

    --distance from obstacle distance
    SIGNAL rear_left, rear_center, rear_right : INTEGER RANGE 0 TO 400;

BEGIN

    -- Instantiate three_ultrasonic component
    ultrasonic_inst : three_ultrasonic
    PORT MAP (
        clk => clk,
        pulse => pulse,
        triggerOut => triggerOut,
        rear_left => rear_left,
        rear_center => rear_center,
        rear_right => rear_right
    );


    -- Instantiate vga_display component
    vga_inst : vga_display
    PORT MAP (
        clk => clk,
        red => red,
        grn => grn,
        blu => blu,
        hsync => hsync,
        vsync => vsync
    );



END ARCHITECTURE helper;
