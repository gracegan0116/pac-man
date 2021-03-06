module animate_pacman (go, resetn, vga_x, vga_y, in_x, out_x, in_y, out_y, colour, done, clock, left, right, up, down, light, win);	
	input go;
	input resetn;
	input clock;
	input left;
	input right;
	input up;
	input down;
	reg writeEn;
	output light;
	output win;
	
	reg go_increment; // for x
	reg go_decrement; // for x
	reg go_increment_init; // for x
	
	reg go_increment_y_init; // for y
	reg go_increment_y; // for y
	reg go_decrement_y; // for y

	parameter [2:0] WAIT = 3'b000, SHIFT = 3'b010, PRINT = 3'b110;
	parameter [6:0] HEIGHT_SCREEN = 7'b1111000;
	parameter [3:0] HEIGHT_EGG = 4'b1010, WIDTH_EGG = 4'b1010;
	parameter [4:0] HEIGHT_PLYR = 5'b10100, WIDTH_PLYR = 5'b10100;
		
	wire [7:0] w_out_x;
	wire [6:0] w_out_y;
//	assign w_out_y = HEIGHT_SCREEN - HEIGHT_PLYR;
	wire done_print; //done signal to know when finished printing
	
	input [7:0] in_x; //original start x
	reg [7:0] w_in_x;
	
	input [6:0] in_y; // original start y
	reg[6:0] w_in_y;
	
	wire [7:0] w_vga_x; 
	wire [6:0] w_vga_y;
	
	output [7:0] vga_x; //all pixels to be printed x
	output [6:0] vga_y; //all pixels to be printed y
	
	output [7:0] out_x; //new shifted start x
	output [6:0] out_y; // new shifted start y
	output [2:0] colour;
	output reg done = 0;
	
	reg [2:0] PresentState, NextState;
	reg [3:0] count;
	always @(*)
	begin : StateTable
		case (PresentState)
		WAIT:
		begin
			done = 0;
			if (go == 0)
				NextState = WAIT;
			else
			begin
				NextState = SHIFT;
			end
		end
		SHIFT:
		begin
			NextState = PRINT;
			done = 0;
		end
		PRINT:
		begin
			if (done_print == 1)
			begin
				NextState = WAIT;
				done = 1;
			end
			else
			begin
				NextState = PRINT;
				done = 0;
			end
		end
		default: 
		begin 
			NextState = WAIT;
			done = 0;
		end
		endcase
	end
	
	// for x
	always @(posedge clock)
	begin
		if (go_increment_init)
		begin
			w_in_x = in_x;
		end 
		else if (go_increment)
			w_in_x = w_in_x + 3'b011;
		else if (go_decrement)
			w_in_x = w_in_x - 3'b011;
	end
	
	// for y
	always @(posedge clock)
	begin			
		if (go_increment_y_init)
		begin
			w_in_y <= in_y;
		end 
		else if (go_increment_y)
			w_in_y <= w_in_y + 3'b011;
		else if (go_decrement_y)
			w_in_y <= w_in_y - 3'b011;
	end
	
	always @(*)
	begin: output_logic
		case (PresentState)
			WAIT:
				begin
					go_increment_init = 1;
					go_increment = 0;
					go_decrement = 0;
					go_increment_y_init = 1;
					go_increment_y = 0;
					go_decrement_y = 0;
					writeEn = 0;
				end
			SHIFT:
				begin
					go_increment_init = 0;
					go_increment_y_init = 0;
					if (up == 0)
					begin
						go_increment = 0;
						go_decrement = 0;
						go_decrement_y = 1;
						go_increment_y = 0;
					end
					else if (down == 0)
					begin
						go_increment = 0;
						go_decrement = 0;
						go_decrement_y = 0;
						go_increment_y = 1;
					end
					
					
					else if (left == 0)
					begin
						go_decrement = 1;
						go_increment = 0;
						go_decrement_y = 0;
						go_increment_y = 0;
					end
					else if (right == 0)
					begin
						go_increment = 1;
						go_decrement = 0;
						go_decrement_y = 0;
						go_increment_y = 0;
					end
					else 
					begin
						go_increment = 0;
						go_decrement = 0;
						go_decrement_y = 0;
						go_increment_y = 0;
					end
					writeEn = 0;
				end
			PRINT:
				begin
					writeEn = 1;
					
					go_increment_init = 0;
					go_increment = 0;
					go_decrement = 0;
					go_increment_y = 0;
					go_decrement_y = 0;
				end
			default:
				begin
					writeEn = 0;
					go_increment_init = 0;
					go_increment = 0;
					go_decrement = 0;
					go_increment_y_init = 0;
					go_increment_y = 0;
					go_decrement_y = 0;
				end
		endcase
	end
	
	always @(posedge clock)
	begin: state_FFs
		if(resetn == 1'b0)
			PresentState <= WAIT;
		else
			PresentState <= NextState;
	end
	

	assign out_x = w_in_x;
	assign w_out_x = w_in_x;
	assign out_y = w_in_y;
	assign w_out_y = w_in_y;
	
	assign vga_x = w_vga_x;
	assign vga_y = w_vga_y;
	
	draw_pacman_right pacman_right (
					.reset(resetn),
					.writeEn(writeEn),
					.x(w_vga_x),
					.y(w_vga_y),
					.startx(w_out_x),
					.starty(w_out_y),
					.clock(clock),
					.colour(colour),
					.done_print(done_print),
					.light(light),
					.win(win)
					);
					

endmodule