// Part 2 skeleton

module background
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,							// On Board Keys
		SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);
//


    input CLOCK_50;
    input [3:0]KEY; 
    input [9:0]SW;

    reg exit;
    output VGA_CLK, VGA_HS,VGA_VS, VGA_BLANK_N,VGA_SYNC_N;
    output [9:0] VGA_R, VGA_G,VGA_B;

    wire left, right, up, down;
    assign left = KEY[2];
    assign right = KEY[1];
	 assign up = KEY[0];
	 assign down = KEY[3];

    wire resetn, clock;
    wire colour;
    wire [7:0]x;
    wire [6:0]y;
    reg [2:0] item_selector;
    reg writeEn;
//
    assign clock = CLOCK_50;
    assign resetn = ~SW[1];
//
    wire done_pacman;
    wire done_bg;

    reg done_wait;

    reg go_pacman;
    reg go_wait;
    reg go_bg;
//
    wire [7:0] pacman_x;
    wire [6:0] pacman_y;
    wire colour_pacman;

    wire[7:0] bg_x;
    wire [6:0] bg_y;
    wire[2:0] colour_bg;

    reg[7:0] start_pacman_x = 80;
    reg [6:0] start_pacman_y = 60;

    wire [7:0] out_pacman_x;
    wire [6:0] out_pacman_y;

    wire [17:0] vga_in;
	 
	 // for test
	 wire done_print;
	
	 mux_vga mux(item_selector, pacman_x, pacman_y, colour_pacman, bg_x, bg_y,colour_bg, vga_in);
    animate_pacman pacman(go_pacman, resetn, pacman_x, pacman_y, start_pacman_x, out_pacman_x, start_pacman_y, out_pacman_y, colour_pacman, done_pacman, CLOCK_50, left, right, up, down);
    draw_bg (go_bg, CLOCK_50,resetn, bg_x, bg_y, colour_bg, done_bg);
	
	
	 reg [27:0] count_wait = 27'b0;
    always @(posedge clock)
    begin 
        if(go_wait)
        begin
            count_wait = count_wait + 1'b1;
            done_wait = 0;

            if(count_wait == 4999999)
            begin   
                count_wait = 27'b0;
                done_wait = 1;
            end
        end
    end

    //MAIN FSM!!!!
    wire start;
    assign start = ~SW[0]; 
    parameter [3:0] INIT = 3'b000, PRINT_BG = 3'b001, PRINT_PACMAN = 3'b010, WAIT = 3'b011;

    reg [3:0] current_state, next_state;

    always@(*)
    begin: State_Table
        case(current_state)
        INIT:
        begin   
            if(start==1)
                next_state = INIT;
            else
                next_state = PRINT_BG;
        end
        PRINT_BG:
        begin
            if(done_bg)
                next_state = PRINT_PACMAN;
            else
                next_state = PRINT_BG;
        end
		  PRINT_PACMAN:
		  begin
			if (done_pacman) 
				next_state = WAIT;
			else
				next_state = PRINT_PACMAN;
			end
        WAIT:
        begin
            if(done_wait)
                next_state = PRINT_BG;
            else
                next_state = WAIT;
        end
        default: next_state = INIT;
        endcase
    end

    always @(*)
    begin: output_logic
        case(current_state)
            INIT:
            begin
                go_wait = 0;
                go_pacman = 0;
                go_bg = 1;
                writeEn = 0;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b000;
            end
            PRINT_BG:
            begin
                go_wait = 0;
                go_pacman = 0;
                go_bg = 1;
                writeEn = 1;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b000;
            end
            PRINT_PACMAN:
            begin
                go_wait = 0;
                go_pacman = 1;
                go_bg = 0;
                writeEn = 1;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b001;
            end
            WAIT:
            begin
                go_wait = 1;
                go_pacman = 0;
                go_bg = 0;
                writeEn =0;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b000;
            end
            default:
            begin
                go_wait = 0;
                go_pacman = 0;
                go_bg = 0;
                writeEn = 0;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b000;
				end
        endcase
    end


    always@(posedge clock)
    begin: state_FFs
        if(resetn == 1'b0)
            current_state <= INIT;
        else
            current_state = next_state;
    end
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(vga_in[0:0]),
			.x(vga_in[15:8]),
			.y(vga_in[7:1]),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	
endmodule
