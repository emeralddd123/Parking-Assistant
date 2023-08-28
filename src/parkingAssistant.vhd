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

    SIGNAL rear_left, rear_center, rear_right : INTEGER RANGE 0 TO 400; -- Declare the signals
    SIGNAL s_hsync, s_vsync : STD_LOGIC;
    SIGNAL s_clk : STD_LOGIC;
    SIGNAL s_triggerOut : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL s_red, s_grn, s_blu : STD_LOGIC_VECTOR(3 DOWNTO 0);
	 
	 SIGNAL c_vva : INTEGER := 480; -- vertical visible area
	 SIGNAL c_hva : INTEGER := 640; -- horizontal visible area
	 
	 --signal vga
    SIGNAL vga : STD_LOGIC_VECTOR((c_hva * c_vva * 24) - 1 DOWNTO 0) := (OTHERS => '0');

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

BEGIN

    ultrasonic_inst : three_ultrasonic
    PORT MAP(
        clk => s_clk,
        pulse => pulse,
        triggerOut => s_triggerOut,
        rear_left => rear_left,
        rear_center => rear_center,
        rear_right => rear_right
    );

    -- Instantiate the vga_display component
    vga_inst : vga_display
    PORT MAP (
        clk => s_clk,
        red => s_red,
        grn => s_grn,
        blu => s_blu,
        hsync => s_hsync,    -- Use the same name for signal and port
        vsync => s_vsync     -- Use the same name for signal and port
    );
    --main process
    output_logic : PROCESS (rear_left, rear_center, rear_right, hposition, vposition)
        -- It is a great idea to use relative positions when placing things on a screen
        -- e.g. instead of saying place a red box between pixels 200 and 400, it is better
        -- to start the red box at position "max_width / 3" etc. That way, if max_width
        -- changes, the box will still be approximately in the same position on the screen.
        VARIABLE color_rear_left : STD_LOGIC_VECTOR(23 DOWNTO 0);
        VARIABLE color_rear_centre : STD_LOGIC_VECTOR(23 DOWNTO 0);
        VARIABLE color_rear_right : STD_LOGIC_VECTOR(23 DOWNTO 0);

        --24 bit color constants
        CONSTANT COLOUR_GREEN : STD_LOGIC_VECTOR(23 DOWNTO 0) := "000000001111111100000000";
        CONSTANT COLOUR_YELLOW : STD_LOGIC_VECTOR(23 DOWNTO 0) := "111111111111111100000000";
        CONSTANT COLOUR_RED : STD_LOGIC_VECTOR(23 DOWNTO 0) := "111111110000000000000000";
		  
		  

        -- Define the distance thresholds
        CONSTANT DIST_THRESHOLD_RED : INTEGER := 50;
        CONSTANT DIST_THRESHOLD_COLOUR_YELLOW : INTEGER := 100;

    BEGIN
        -- Determine the color for each rectangle based on distance from obstcles
        IF rear_left > DIST_THRESHOLD_COLOUR_YELLOW THEN
            color_rear_left := COLOUR_GREEN;
        ELSIF rear_left > DIST_THRESHOLD_RED THEN
            color_rear_left := COLOUR_YELLOW;
        ELSE
            color_rear_left := COLOUR_RED;
        END IF;

        IF rear_center > DIST_THRESHOLD_COLOUR_YELLOW THEN
            color_rear_centre := COLOUR_GREEN;
        ELSIF rear_center > DIST_THRESHOLD_RED THEN
            color_rear_centre := COLOUR_YELLOW;
        ELSE
            color_rear_centre := COLOUR_RED;
        END IF;

        IF rear_right > DIST_THRESHOLD_COLOUR_YELLOW THEN
            color_rear_right := COLOUR_GREEN;
        ELSIF rear_right > DIST_THRESHOLD_RED THEN
            color_rear_right := COLOUR_YELLOW;
        ELSE
            color_rear_right := COLOUR_RED;
        END IF;

        vga <= generate_rectangle(100, 300, 100, 30, color_rear_left, c_hva) OR
            generate_rectangle(300, 300, 100, 30, color_rear_centre, c_hva) OR
            generate_rectangle(500, 300, 100, 30, color_rear_right, c_hva);

    END PROCESS; -- output_logic
		
		clk <= s_clk;
    hsync <= s_hsync;
    vsync <= s_vsync;
    red <= vga(23 DOWNTO 16);
    grn <= vga(15 DOWNTO 8);
    blu <= vga(7 DOWNTO 0);
	 triggerOut <= s_triggerOut;

END ARCHITECTURE helper;
