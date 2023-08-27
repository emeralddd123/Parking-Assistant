LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY vga_display IS
    PORT (
        clk : IN STD_LOGIC;
        red, grn, blu : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        hsync, vsync : OUT STD_LOGIC
    );
END ENTITY vga_display;

ARCHITECTURE display OF vga_display IS
    CONSTANT clk_freq : INTEGER := 50e6; -- The clock frequency of the DE10-Lite is 50 MHz.

    -- Define the distance thresholds
    CONSTANT DIST_THRESHOLD_RED : INTEGER := 50;
    CONSTANT DIST_THRESHOLD_YELLOW : INTEGER := 100;

    -- -- Signals that will hold the parameters at any point in time for a 640x480 display
    SIGNAL hfp : INTEGER := 16; -- horizontal front porch
    SIGNAL hsp : INTEGER := 96; -- horizontal sync pulse
    SIGNAL hbp : INTEGER := 48; -- horizontal back porch
    SIGNAL hva : INTEGER := 640; -- horizontal visible area
    SIGNAL vfp : INTEGER := 11; -- vertical front porch
    SIGNAL vsp : INTEGER := 2; -- vertical sync pulse
    SIGNAL vbp : INTEGER := 31; -- vertical back porch
    SIGNAL vva : INTEGER := 480; -- vertical visible area

    -- Signals for each of the clocks available to us VGA works with 25MHz
    SIGNAL clk25 : STD_LOGIC;

    -- Signals to hold the present horizontal and vertical positions.
    SIGNAL hposition : INTEGER RANGE 0 TO 4000 := 0;
    SIGNAL vposition : INTEGER RANGE 0 TO 4000 := 0;

    --
    --
    --
FUNCTION generate_rectangle(h_pos : INTEGER; v_pos : INTEGER;
        width : INTEGER;
        height : INTEGER;
        color : INTEGER;
        hva : INTEGER)
        RETURN STD_LOGIC_VECTOR IS
    VARIABLE vga_signal : STD_LOGIC_VECTOR((hva - 1) DOWNTO 0);
    VARIABLE x, y : INTEGER;
    VARIABLE color_vector : STD_LOGIC_VECTOR(23 DOWNTO 0); -- 24-bit color representation
BEGIN
    vga_signal := (OTHERS => '0'); -- Initialize VGA signal
    
    -- Convert the integer color value to a 24-bit std_logic_vector
    color_vector := std_logic_vector(to_unsigned(color, color_vector'LENGTH));

    FOR y IN v_pos TO v_pos + height - 1 LOOP
        FOR x IN h_pos TO h_pos + width - 1 LOOP
            vga_signal(x * color_vector'LENGTH + color_vector'LENGTH - 1 DOWNTO x * color_vector'LENGTH) := color_vector; -- Set pixel color
        END LOOP;
    END LOOP;

    RETURN vga_signal;
END FUNCTION;


BEGIN
disp_clk: work.clk25 port map( inclk0 => clk,
												 c0	 => clk25);

    output_logic : PROCESS (rear_left, rear_center, rear_right, hposition, vposition)
        -- It is a great idea to use relative positions when placing things on a screen
        -- e.g. instead of saying place a red box between pixels 200 and 400, it is better
        -- to start the red box at position "max_width / 3" etc. That way, if max_width
        -- changes, the box will still be approximately in the same position on the screen.
        VARIABLE hoffset : INTEGER := hfp + hsp + hbp;
        VARIABLE voffset : INTEGER := vfp + vsp + vbp;

        VARIABLE h1quarter : INTEGER := hoffset + hva / 4;
        VARIABLE hcentre : INTEGER := hoffset + hva / 2;
        VARIABLE h3quarters : INTEGER := hoffset + 3 * hva / 4;
        VARIABLE v1quarter : INTEGER := voffset + vva / 4;
        VARIABLE vcentre : INTEGER := voffset + vva / 2;
        VARIABLE v3quarters : INTEGER := voffset + 3 * vva / 4;

        VARIABLE h_light_centre1 : INTEGER := hoffset + (hva / 4);
        VARIABLE h_light_centre2 : INTEGER := hoffset + 3 * (hva / 4);
        VARIABLE light_width : INTEGER := (hva / 10);
        VARIABLE light_height : INTEGER := vva/10;
        VARIABLE color_rear_left : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE color_rear_centre : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE color_rear_right : STD_LOGIC_VECTOR(7 DOWNTO 0);
    BEGIN
        -- Determine the color for each rectangle based on distance from obstcles
        IF rear_left > DIST_THRESHOLD_YELLOW THEN
            color_rear_left := green;
        ELSIF rear_left > DIST_THRESHOLD_RED THEN
            color_rear_left := yellow;
        ELSE
            color_rear_left := red;
        END IF;

        IF rear_center > DIST_THRESHOLD_YELLOW THEN
            color_rear_centre := green;
        ELSIF rear_center > DIST_THRESHOLD_RED THEN
            color_rear_centre := yellow;
        ELSE
            color_rear_centre := red;
        END IF;

        IF rear_right > DIST_THRESHOLD_YELLOW THEN
            color_rear_right := green;
        ELSIF rear_right > DIST_THRESHOLD_RED THEN
            color_rear_right := yellow;
        ELSE
            color_rear_right := red;
        END IF;

        -- Using the generate_rectangle function with different colors
        vga <= generate_rectangle(h_rear_left, v_rear, light_width, light_height, color_rear_left);
        vga <= vga OR generate_rectangle(h_rear_centre, v_rear, light_width, light_height, color_rear_centre);
        vga <= vga OR generate_rectangle(h_rear_right, v_rear, light_width, light_height, color_rear_right);


        END PROCESS; -- output_logic
    --
    --
    --
    display_things : PROCESS (clk25)
    BEGIN
        -- When horizontal position counter gets to the last pixel in a row, go back
        -- to zero and increment the vertical counter (i.e. go to start of next line)
        -- else increase hposition by 1
        IF rising_edge(clk25) THEN
            IF hposition >= (hfp + hsp + hbp + hva) THEN
                hposition <= 0;
                -- when vertical position counter gets to the end of rows, go back to the
                -- start of the first row else increment vposition by 1
                IF vposition >= (vfp + vsp + vbp + vva) THEN
                    vposition <= 0;
                ELSE
                    vposition <= vposition + 1;
                END IF;
            ELSE
                hposition <= hposition + 1;
            END IF;

            -- Generate horizontal synch pulse whenever the hposition is between the front
            -- porch and the back porch
            IF (hposition >= hfp) AND (hposition < (hfp + hsp)) THEN
                hsync <= '0';
            ELSE
                hsync <= '1';
            END IF;

            -- Generate vertical synch pulse whenever the vposition is between the front
            -- porch and the back porch
            IF (vposition >= vfp) AND (vposition < (vfp + vsp)) THEN
                vsync <= '0';
            ELSE
                vsync <= '1';
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE display;