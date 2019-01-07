module check_maze (input clk, input [7:0] xIn, input [6:0] yIn, output reg isWhite, output reg win);
	wire mapOutZero;
	wire mapOutOne;
	wire mapOutTwo;
	wire mapOutThree;
	
	wire mapoutFour;
	wire mapOutFive;
	wire mapOutSix;
	wire mapOutSeven;
	
	bg_mono bg(
	.address(xIn + 160 * yIn),
	.clock(clk),
	.q(mapOutZero));
	
	bg_mono bg1(
	.address((xIn + 5'b1) + 160 * yIn),
	.clock(clk),
	.q(mapOutOne));
	
	bg_mono bg2(
	.address((xIn + 5'b1) + 160 * (yIn + 5'b1)),
	.clock(clk),
	.q(mapOutTwo));

	bg_mono bg3(
	.address(xIn + 160 * (yIn + 5'b1)),
	.clock(clk),
	.q(mapOutThree));
	
	// check maze
	always @ (posedge clk) begin
		if (mapOutZero == 1 || mapOutOne == 1 || mapOutTwo == 1 || mapOutThree == 1) begin
			isWhite <= 1'b1;
		end
		
		else
			isWhite <= 1'b0;
	end
	
	// check win
	always@(posedge clk) begin
		if (xIn >= 8'b10010100 && yIn >= 7'b1101110) begin
			win <= 1'b1;
		end
		else
			win <= 1'b0;
	end
	
endmodule
