module top
	(
		CLOCK_50,						//	On Board 50 MHz
		SW, 
		KEY, 
		LEDR,
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		HEX4,
		HEX5,
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						 //	VGA Blue[9:0]
	);
	
	// Declare your inputs and outputs here
	input [9:0] SW;
	input [3:0] KEY;   
	input CLOCK_50;
   
	output [9:0] LEDR; 
	output [6:0] HEX0,HEX1,HEX2,HEX3,HEX4, HEX5;
	
	reg exit;
	
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
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

    assign clock = CLOCK_50;
    assign resetn = ~SW[1];

    wire done_pacman;
    wire done_bg;
	 
	 wire done_win; 
	 wire done_over;
	 wire done_exit;

    reg done_wait;

    reg go_pacman;
    reg go_wait;
    reg go_bg;
	 reg go_win;
	 reg go_over;
	 reg go_exit;
	 
//
    wire [7:0] pacman_x;
    wire [6:0] pacman_y;
    wire colour_pacman;

    wire[7:0] bg_x;
    wire [6:0] bg_y;
    wire colour_bg;
	 
	 wire[7:0] win_x;
    wire [6:0] win_y;
	 wire colour_win; // win game
	 
	 wire[7:0] gameover_x;
    wire [6:0] gameover_y;
	 wire colour_over; // game over
	 
	 wire[7:0] exit_x;
	 wire[6:0] exit_y;
	 wire exit_colour;
	 
	 wire touch_maze; // check maze
	 wire is_win; // check win
	 wire timeout;

    reg[7:0] start_pacman_x = 8'b00000000;
    reg [6:0] start_pacman_y = 7'b0000000;
	 
	parameter [6:0] HEIGHT_SCREEN = 7'b1111000;
	parameter [7:0] WIDTH_SCREEN = 8'b10100000;
	parameter [3:0] HEIGHT_EGG = 4'b1010, WIDTH_EGG = 4'b1010;
	parameter [4:0] HEIGHT_PLYR = 5'b10100, WIDTH_PLYR = 5'b10100;

    wire [7:0] out_pacman_x;
    wire [6:0] out_pacman_y;

    wire [17:0] vga_in;
	 
	 // for test
	 wire done_print;
	
	 mux_vga mux(item_selector, pacman_x, pacman_y, colour_pacman, bg_x, bg_y,colour_bg, gameover_x, gameover_y, colour_over, win_x, win_y, colour_win, exit_x, exit_y, exit_colour, vga_in);
    animate_pacman pacman(go_pacman, resetn, pacman_x, pacman_y, start_pacman_x, out_pacman_x, start_pacman_y, out_pacman_y, colour_pacman, done_pacman, CLOCK_50, left, right, up, down, touch_maze, is_win);
    draw_bg (go_bg, CLOCK_50,resetn, bg_x, bg_y, colour_bg, done_bg);
	 draw_over(go_over, CLOCK_50, resetn, gameover_x, gameover_y, colour_over, done_over);
	 draw_win(go_win, CLOCK_50, resetn, win_x, win_y, colour_win, done_win);
	 draw_exit(go_exit, CLOCK_50, resetn, exit_x, exit_y, exit_colour, done_exit);
	 
	 counter_ten(CLOCK_50, start, resetn, HEX0, HEX1, timeout);
	
	// for wait state
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
    parameter [3:0] INIT = 4'b0000, 
						  PRINT_BG = 4'b0001, 
						  PRINT_PACMAN = 4'b0010, 
						  WAIT = 4'b0011, 
						  CHECK = 4'b0100, 
						  GAME_OVER = 4'b0101, 
						  GAME_WIN = 4'b0110,
						  PRINT_EXIT = 4'b0111;

    reg [3:0] current_state, next_state;
	 
	 assign LEDR[0] = touch_maze;
	 assign LEDR[1] = is_win;
	 assign LEDR[2] = timeout;

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
                next_state = PRINT_EXIT;
            else
                next_state = PRINT_BG;
        end
		  PRINT_EXIT:
		  begin
			if(done_exit)
				next_state = CHECK;
			else
				next_state = PRINT_EXIT;
		  end
		  CHECK:
		  begin 
			if (touch_maze || timeout) 
				next_state = GAME_OVER;
			else if (is_win)
				next_state = GAME_WIN;
			else
				next_state = PRINT_PACMAN;
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

		  GAME_OVER:
		  begin 
				if (done_over)
					next_state = GAME_OVER;
				else
					next_state = GAME_OVER;
		  end
		  GAME_WIN:
		  begin
			if (done_win)
				next_state = GAME_WIN;
			else
				next_state = GAME_WIN;
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
					 go_over = 0; // changed here
					 go_win = 0;
					 go_exit = 0;
                writeEn = 0;
                start_pacman_x = HEIGHT_PLYR/2;
					 start_pacman_y = HEIGHT_PLYR/2;
                item_selector = 3'b000;
            end
            PRINT_BG:
            begin
                go_wait = 0;
                go_pacman = 0;
                go_bg = 1;
					 go_over = 0;
					 go_win = 0;
					 go_exit = 0;
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
					 go_over = 0;
					 go_win = 0;
					 go_exit = 0;
                writeEn = 1;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b001;
            end
				CHECK:
				begin
					 go_wait = 0;
                go_pacman = 0;
                go_bg = 0;
					 go_over = 0;
					 go_win = 0;
					 go_exit = 0;
                writeEn = 1;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b000;
		      end
            WAIT:
            begin
                go_wait = 1;
                go_pacman = 0;
                go_bg = 0;
					 go_over = 0;
					 go_win = 0;
					 go_exit = 0;
                writeEn =0;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b000;
            end
				GAME_OVER:
				begin
					 go_wait = 0;
                go_pacman = 0;
                go_bg = 0;
					 go_over = 1;
					 go_win = 0;
					 go_exit = 0;
                writeEn =1;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b011;
				end
				GAME_WIN:
				begin
					 go_wait = 0;
                go_pacman = 0;
                go_bg = 0;
					 go_over = 0;
					 go_win = 1;
					 go_exit = 0;
                writeEn =1;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b010;
				end
				PRINT_EXIT:
				begin
					 go_wait = 0;
                go_pacman = 0;
                go_bg = 0;
					 go_over = 0;
					 go_win = 0;
					 go_exit = 1;
                writeEn =1;
                start_pacman_x = out_pacman_x;
					 start_pacman_y = out_pacman_y;
                item_selector = 3'b100;
				end
            default:
            begin
                go_wait = 0;
                go_pacman = 0;
                go_bg = 0;
					 go_over = 0;
					 go_win = 0;
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
		defparam VGA.MONOCHROME = "TRUE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
		
endmodule


module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule

module counter_ten(input CLOCK_50, input start, input resetn, output [6:0]H, output [6:0] H1, output timeout);
    wire W1; 
    wire [25:0] W2; 
    wire [4:0] Qout;
    EnableSignalOneSec ES1(.Clk(CLOCK_50), .Clear_b(resetn), .enable(start), .Q(W2)); 
    assign W1 = (W2 == 0)?1:0;
    Counter C1(.Enable(W1), .Clk(CLOCK_50), .Clear_b(resetn) , .Q(Qout), .timeout(timeout)); 
    hexdecoder H0(.C({1'b0, Qout}), .h0(H), .h1(H1));  

endmodule // HexCounter

module Counter(input Enable, Clk, Clear_b, output reg [4:0]Q, output reg timeout); 
    always @(posedge Clk) 
    begin
        if(Clear_b == 1'b0) begin
            Q <= 5'b10100;
				timeout <= 1'b0;
			end
        else if(Q == 5'b00000) begin
            Q <= 5'b00000; 
				timeout <= 1'b1;
	     end
        else if(Enable == 1'b1) begin
            Q <= Q - 1; 
				timeout <= 1'b0;
		  end	
    end
endmodule // Counter

module EnableSignalOneSec(input Clear_b, Clk, enable, output reg [25:0]Q); 
    always @(posedge Clk) 
    begin
        if(Clear_b == 1'b0)
            Q <= 26'b0000000000000000000000000;  
        else if (enable) 
              Q <= 26'b10111110101111000001111111;
		else
            Q <= Q - 1; 
	end
endmodule

module hexdecoder(input[5:0] C, output[6:0] h0, output [6:0] h1);


  assign h0[0] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & !C[0]);
						
						
						
	assign h0[1] = (!C[5] & !C[4] & !C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & !C[0]);
						
	
	assign h0[2] = (!C[5] & !C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & !C[0]);
						
	
	
	assign h0[3] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & C[0])  ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & C[0]);
						
						
						
	assign h0[4] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & C[0]) || 
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & C[0]);
						
						
						
	assign h0[5] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & !C[0]);
						
	
	
	assign h0[6] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & C[0])||
						(!C[5] & C[4] & !C[3] & C[2] & !C[1] & !C[0]);
						
	
	
	assign h1[0] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & C[0]) || 
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & !C[0]);
						
						
	assign h1[1] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & C[0]);
	
	
	assign h1[2] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & C[2] & !C[1] & !C[0]);
						
						
	assign h1[3] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & !C[0]); 
						
						
	assign h1[4] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & !C[0]);
						
						
	assign h1[5] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & !C[0]);
						
						
	assign h1[6] = (!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & !C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & !C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & !C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & !C[1] & C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & !C[0]) ||
						(!C[5] & C[4] & !C[3] & !C[2] & C[1] & C[0]) ||
						(!C[5] & !C[4] & C[3] & C[2] & !C[1] & !C[0]);
endmodule


// hexdecoder
module HEX(input [3:0]B, output [6:0]S);
    wire [6:0]W; wire [3:0]D;
    assign D = B;
    assign W[0] = !((!D[0]|D[1]|D[2]|D[3]) & (D[0]|D[1]|!D[2]|D[3]) & (!D[0]|!D[1]|D[2]|!D[3]) & (!D[0]|D[1]|!D[2]|!D[3]));
    assign W[1] = !((!D[0]|D[1]|!D[2]|D[3]) & (D[0]|!D[1]|!D[2]|D[3]) & (!D[0]|!D[1]|D[2]|!D[3]) & (D[0]|D[1]|!D[2]|!D[3]) & (D[0]|!D[1]|!D[2]|!D[3]) & (!D[0]|!D[1]|!D[2]|!D[3]));
    assign W[2] = !((D[0]|!D[1]|D[2]|D[3]) & (D[0]|D[1]|!D[2]|!D[3]) & (D[0]|!D[1]|!D[2]|!D[3]) & (!D[0]|!D[1]|!D[2]|!D[3]));
    assign W[3] = !((!D[0]|D[1]|D[2]|D[3]) & (D[0]|D[1]|!D[2]|D[3]) & (!D[0]|!D[1]|!D[2]|D[3]) & (D[0]|!D[1]|D[2]|!D[3]) & (!D[0]|!D[1]|!D[2]|!D[3]));
    assign W[4] = !((!D[0]|D[1]|D[2]|D[3]) & (!D[0]|!D[1]|D[2]|D[3]) & (D[0]|D[1]|!D[2]|D[3]) & (!D[0]|D[1]|!D[2]|D[3]) & (!D[0]|!D[1]|!D[2]|D[3]) & (!D[0]|D[1]|D[2]|!D[3]));
    assign W[5] = !((!D[0]|D[1]|D[2]|D[3]) & (D[0]|!D[1]|D[2]|D[3]) & (!D[0]|!D[1]|D[2]|D[3]) & (!D[0]|!D[1]|!D[2]|D[3])&(!D[0]|D[1]|!D[2]|!D[3]));
    assign W[6] = !((D[0]|D[1]|D[2]|D[3]) & (!D[0]|D[1]|D[2]|D[3]) & (!D[0]|!D[1]|!D[2]|D[3]) & (D[0]|D[1]|!D[2]|!D[3]));
    assign S = W;
endmodule // hexDecoder
