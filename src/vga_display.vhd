LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY vga_display IS
    PORT (
        clk : IN STD_LOGIC;
        red, grn, blu : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        hsync, vsync : OUT STD_LOGIC;
        rear_left, rear_center, rear_right : IN INTEGER RANGE 0 TO 400
    );
END ENTITY vga_display;

ARCHITECTURE display OF vga_display IS
    CONSTANT clk_freq : INTEGER := 50e6; -- The clock frequency of the DE10-Lite is 50 MHz.

    

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

    

    --signal for the distances
    --SIGNAL rear_left, rear_center, rear_right : INTEGER RANGE 0 TO 400;

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


    
    FUNCTION generate_rectangle(h_pos : INTEGER; v_pos : INTEGER;
        width : INTEGER;
        height : INTEGER;
        color : STD_LOGIC_VECTOR(23 DOWNTO 0);
        hva : INTEGER)
        RETURN STD_LOGIC_VECTOR IS
        VARIABLE vga_signal : STD_LOGIC_VECTOR((hva - 1) DOWNTO 0);
        VARIABLE x, y : INTEGER;
        VARIABLE color_vector : STD_LOGIC_VECTOR(23 DOWNTO 0); -- 24-bit color representation
    BEGIN
        vga_signal := (OTHERS => '0'); -- Initialize VGA signal

        -- Convert the integer color value to a 24-bit std_logic_vector
        color_vector := color;

        FOR y IN v_pos TO v_pos + height - 1 LOOP
            FOR x IN h_pos TO h_pos + width - 1 LOOP
                vga_signal(x * color_vector'LENGTH + color_vector'LENGTH - 1 DOWNTO x * color_vector'LENGTH) := color_vector; -- Set pixel color
            END LOOP;
        END LOOP;

        RETURN vga_signal;
    END FUNCTION;
BEGIN
    disp_clk : work.clk25 PORT MAP(inclk0 => clk,
    c0 => clk25);

    
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