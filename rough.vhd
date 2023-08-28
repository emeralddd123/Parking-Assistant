LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fsm2 IS
    PORT (
        clk, rst : IN STD_LOGIC;
        sel_resolution : IN STD_LOGIC;
        red, grn, blu : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        hsync, vsync : OUT STD_LOGIC;
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END ENTITY fsm2;

ARCHITECTURE display OF fsm2 IS
    CONSTANT clk_freq : INTEGER := 50e6; -- The clock frequency of the DE10-Lite is 50 MHz.
    -- Having this constant makes it possible to use it later for computations in seconds.

    -- Below are a number of definitions of constants that can be written directly to the seven
    -- segment displays. While you wll not need these most of the times, it is often good to 
    -- have these defines somewhere and then you can bring them into whatever project you want
    -- later. Feel free to modify the below to your taste.
    -- When done with all these definitions, you can simply write the constant to the HEX output
    -- and the LED should light up as designed e.g. HEX0 <= A; should display 'A' on HEX0.
    CONSTANT A : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0001000";
    CONSTANT b : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000011";
    CONSTANT c : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0100111";
    CONSTANT d : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0100111";
    CONSTANT E : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000110";
    CONSTANT F : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0001110";

    -- TODO: Fill in as many letters as you can here. Not all letters can really be displayed on a single
    -- seven-segment display. However, it is possible to display a letter like m and w by making use
    -- of two adjacent segments e.g. rn reasonably looks like m
    -- Also, letters s and number 5 are the same and 2 and z can be considered the same. Hence, you
    -- can write 2 instead of z on the segment and that can work.
    CONSTANT r : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0101111";
    CONSTANT t : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000111";

    CONSTANT blank : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111111";

    CONSTANT zero : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000000";
    CONSTANT one : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111001";
    CONSTANT two : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0100100";
    CONSTANT three : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0110000";
    CONSTANT four : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0011001";
    CONSTANT five : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010010";
    CONSTANT six : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000010";
    CONSTANT seven : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111000";
    CONSTANT eight : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000000";
    CONSTANT nine : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0011000";

    TYPE state IS (reset, NS, EW);
    SIGNAL pres_state, next_state : state;

    SIGNAL clk_1Hz : STD_LOGIC;

    CONSTANT state0_duration : INTEGER := 3;
    CONSTANT state1_duration : INTEGER := 5;
    CONSTANT state2_duration : INTEGER := 4;

    -- Parameters for a 640x480 display
    CONSTANT hfp480p : INTEGER := 16;
    CONSTANT hsp480p : INTEGER := 96;
    CONSTANT hbp480p : INTEGER := 48;
    CONSTANT hva480p : INTEGER := 640;
    CONSTANT vfp480p : INTEGER := 11;
    CONSTANT vsp480p : INTEGER := 2;
    CONSTANT vbp480p : INTEGER := 31;
    CONSTANT vva480p : INTEGER := 480;
    --TODO: create constants for at least one more display resolution

    -- Parameters for a 1024x768 display
    CONSTANT hfp768p : INTEGER := 24;
    CONSTANT hsp768p : INTEGER := 136;
    CONSTANT hbp768p : INTEGER := 160;
    CONSTANT hva768p : INTEGER := 1024;
    CONSTANT vfp768p : INTEGER := 3;
    CONSTANT vsp768p : INTEGER := 6;
    CONSTANT vbp768p : INTEGER := 29;
    CONSTANT vva768p : INTEGER := 768;

    -- Signals that will hold the parameters at any point in time
    SIGNAL hfp : INTEGER; -- horizontal front porch
    SIGNAL hsp : INTEGER; -- horizontal sync pulse
    SIGNAL hbp : INTEGER; -- horizontal back porch
    SIGNAL hva : INTEGER; -- horizontal visible area
    SIGNAL vfp : INTEGER; -- vertical front porch
    SIGNAL vsp : INTEGER; -- vertical sync pulse
    SIGNAL vbp : INTEGER; -- vertical back porch
    SIGNAL vva : INTEGER; -- vertical visible area
    -- Signal to hold the clock we will use for the display
    SIGNAL sync_clk : STD_LOGIC;
    SIGNAL s_clk : STD_LOGIC;
    -- Signals for each of the clocks available to us
    SIGNAL clk25 : STD_LOGIC;
    -- TODO: create a second signal for your second clock for the second resolution

    -- for the 1024x768 display chosen, it requires 65 MHz
    SIGNAL clk65 : STD_LOGIC;
    -- Signals to hold the present horizontal and vertical positions.
    SIGNAL hposition : INTEGER RANGE 0 TO 4000 := 0;
    SIGNAL vposition : INTEGER RANGE 0 TO 4000 := 0;

    SIGNAL car_image_address : STD_LOGIC_VECTOR(13 DOWNTO 0);
    SIGNAL car_image : STD_LOGIC_VECTOR(11 DOWNTO 0);
    CONSTANT image_width : INTEGER := 201;
    CONSTANT image_height : INTEGER := 63;
BEGIN
    s_clk <= clk;

    disp_clk : work.sync_clk PORT MAP(inclk0 => clk,
    c0 => clk25,
    c1 => clk65);
    mem1 : work.car_pic PORT MAP(address => car_image_address, clock => s_clk, q => car_image);
    -- Process to create 1Hz clock for use in the program.
    create_1Hz_clk : PROCESS (clk, rst)
        VARIABLE cnt : INTEGER RANGE 0 TO clk_freq := 0;
    BEGIN
        IF rst = '0' THEN
            cnt := 0;
        ELSIF rising_edge(clk) THEN
            IF cnt >= clk_freq/2 THEN
                clk_1Hz <= NOT clk_1Hz;
                cnt := 0;
            ELSE
                cnt := cnt + 1;
            END IF;
        END IF;
    END PROCESS;
    -- The FSM below is designed using the three-process method.
    -- The first process is for ensures that states get updated only on the active clock transitions.
    -- The second process determines holds the rules that governs what the next state to go to is.
    -- The third process governs the output rules.

    -- The first process resets the FSM if an active reset signal is received. Otherwise, on every
    -- active clock transition, it checks what the next state should be and updates the FSM accordingly.
    sync_state_transition : PROCESS (clk, rst)
    BEGIN
        IF (rst = '0') THEN
            pres_state <= reset;
        ELSIF rising_edge(clk) THEN
            pres_state <= next_state;
        END IF;
    END PROCESS;

    -- This process controls what the next state will be. Hence, it holds the state transition logic.
    -- TODO
    state_transition_logic : PROCESS (pres_state, clk_1Hz, rst)
        VARIABLE cnt : INTEGER RANGE 0 TO 7 := 0;
    BEGIN
        IF rst = '0' THEN
            cnt := 0; -- to ensure that the counter is reset when reset btn is pressed.
            next_state <= reset; -- to ensure that the value in next_state is also changed to reset
            -- if this is not done, the FSM may return to its previous state once the reset
            -- button is released.
        ELSIF rising_edge(clk_1Hz) THEN -- this is needed only because this FSM used a counter.
            CASE pres_state IS
                WHEN reset =>
                    IF cnt >= state0_duration THEN
                        cnt := 0;
                        next_state <= NS;
                    ELSE
                        cnt := cnt + 1;
                        next_state <= reset;
                    END IF;
                WHEN NS =>
                    IF cnt >= state1_duration THEN
                        cnt := 0;
                        next_state <= EW;
                    ELSE
                        cnt := cnt + 1;
                    END IF;
                WHEN EW =>
                    IF cnt >= state2_duration THEN
                        cnt := 0;
                        next_state <= NS;
                    ELSE
                        cnt := cnt + 1;
                    END IF;
            END CASE;
        END IF;
    END PROCESS;

    -- The third process controls the rules that determine the output in each state.
    -- This FSM is designed as a MOORE FSM so the outputs here are only dependent on the present state
    -- Hence, the process sensitivity list only has the present state signal.
    -- 
    -- In this process, we determine what value of r, g and b to write to each pixel.
    -- Processes below control the hposition and vposition. Hence, in this FSM output 
    -- process we can determine what colour to display for each hposition and vposition
    -- TODO
    output_logic : PROCESS (pres_state, car_image, hposition, vposition)
        -- It is a great idea to use relative positions when placing things on a screen
        -- e.g. instead of saying "place a red box between pixels 200 and 400, it is better
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
        VARIABLE v_red_light_centre : INTEGER := voffset + (4 * vva/20);
        VARIABLE v_amb_light_centre : INTEGER := voffset + (8 * vva/20);
        VARIABLE v_grn_light_centre : INTEGER := voffset + (12 * vva/20);
    BEGIN
        CASE pres_state IS
            WHEN reset =>
                HEX5 <= r;
                HEX4 <= E;
                HEX3 <= five;
                HEX2 <= E;
                HEX1 <= t;
                HEX0 <= blank;

                -- TODO: The code below displays the three lights
                -- Modify the code to display only the correct light(s).
                -- You can choose whatever shape of light you want.

                -- These will draw the red and amber lights as a square

                IF ((hposition >= h_light_centre1 - light_width/2) AND (hposition < (h_light_centre1 + light_width/2)) AND (vposition >= v_amb_light_centre - light_height/2) AND (vposition < (v_amb_light_centre + light_height/2))) THEN -- first traffic light amber
                    red <= x"f";
                    grn <= x"f";
                    blu <= x"1";
                ELSIF ((hposition >= h_light_centre2 - light_width/2) AND (hposition < (h_light_centre2 + light_width/2)) AND (vposition >= v_amb_light_centre - light_height/2) AND (vposition < (v_amb_light_centre + light_height/2))) THEN -- second traffic light amber
                    red <= x"f";
                    grn <= x"f";
                    blu <= x"1";

                ELSE
                    red <= x"1";
                    grn <= x"1";
                    blu <= x"1";
                END IF;

            WHEN NS =>
                HEX5 <= blank;
                HEX4 <= blank;
                HEX3 <= blank;
                HEX2 <= blank;
                HEX1 <= blank;
                HEX0 <= one;

                -- TODO: The code below displays the three lights
                -- Modify the code to display only the correct light(s).
                -- You can choose whatever shape of light you want.

                IF (((hposition - h_light_centre2) ** 2) + ((vposition - v_red_light_centre) ** 2) <= ((light_width/2) ** 2)) THEN --second traffic light red
                    red <= x"f";
                    grn <= x"1";
                    blu <= x"1";

                ELSIF (((hposition - h_light_centre1) ** 2) + ((vposition - v_grn_light_centre) ** 2) <= ((light_width/2) ** 2)) THEN --first traffic light green
                    red <= x"1";
                    grn <= x"f";
                    blu <= x"1";
                    -- The image of the car here is rotated horizontally to the original image in the memory
                ELSIF ((hposition >= h1quarter - image_width/2) AND (hposition < h1quarter + image_width/2)) AND ((vposition >= v3quarters - image_height/2) AND (vposition < v3quarters + image_height/2)) THEN
                    car_image_address <= STD_LOGIC_VECTOR(to_unsigned((image_width - (hposition - (h1quarter - image_width/2))) + (vposition - (v3quarters - image_height/2)) * image_width, 14));
                    red <= car_image(11 DOWNTO 8);
                    grn <= car_image(7 DOWNTO 4);
                    blu <= car_image(3 DOWNTO 0);
                ELSE
                    red <= x"1";
                    grn <= x"1";
                    blu <= x"1";
                END IF;
            WHEN EW =>
                HEX5 <= blank;
                HEX4 <= blank;
                HEX3 <= blank;
                HEX2 <= blank;
                HEX1 <= blank;
                HEX0 <= two;

                -- This places an image of the car facing the opposite direction to the one above.
                IF ((hposition >= h3quarters - image_width/2) AND (hposition < h3quarters + image_width/2)) AND ((vposition >= v3quarters - image_height/2) AND (vposition < v3quarters + image_height/2)) THEN
                    car_image_address <= STD_LOGIC_VECTOR(to_unsigned((hposition - (h3quarters - image_width/2)) + (vposition - (v3quarters - image_height/2)) * image_width, 14));
                    red <= car_image(11 DOWNTO 8);
                    grn <= car_image(7 DOWNTO 4);
                    blu <= car_image(3 DOWNTO 0);
                ELSIF (((hposition - h_light_centre1) ** 2) + ((vposition - v_red_light_centre) ** 2) <= ((light_width/2) ** 2)) THEN --first traffic light red
                    red <= x"f";
                    grn <= x"1";
                    blu <= x"1";
                ELSIF (((hposition - h_light_centre2) ** 2) + ((vposition - v_grn_light_centre) ** 2) <= ((light_width/2) ** 2)) THEN --second traffic light green
                    red <= x"1";
                    grn <= x"f";
                    blu <= x"1";
                ELSE
                    red <= x"1";
                    grn <= x"1";
                    blu <= x"1";
                END IF;
        END CASE;
    END PROCESS;
    -- The code below controls the display

    -- TODO delete this process as you are to use the PLL IP instead to generate your needed clocks
    -- TODO update this process to cater for the specified displays
    choose_disp_params : PROCESS (sel_resolution, clk25, clk65)
    BEGIN
        IF sel_resolution = '0' THEN
            sync_clk <= clk25; -- 
            hfp <= hfp480p;
            hsp <= hsp480p;
            hbp <= hbp480p;
            hva <= hva480p;
            vfp <= vfp480p;
            vsp <= vsp480p;
            vbp <= vbp480p;
            vva <= vva480p;
        ELSE
            sync_clk <= clk65; -- 
            hfp <= hfp768p;
            hsp <= hsp768p;
            hbp <= hbp768p;
            hva <= hva768p;
            vfp <= vfp768p;
            vsp <= vsp768p;
            vbp <= vbp768p;
            vva <= vva768p;
        END IF;
    END PROCESS;
    display_things : PROCESS (sync_clk)
    BEGIN
        -- When horizontal position counter gets to the last pixel in a row, go back
        -- to zero and increment the vertical counter (i.e. go to start of next line)
        -- else increase hposition by 1
        IF rising_edge(sync_clk) THEN
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