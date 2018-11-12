module control (input clk, reset_n, 
    input done_draw, update_frame, up, left, right, down 
    output reg o_sel_black, o_draw, o_update_x_y, o_en_counter);
    reg[3:0] curr_state, next_state;

    reg go;
    always@(*) begin
        assign go = left ^ right ^ up ^ down;
    end
    localparam  S_INIT       = 3'd0,
                S_DRAW  = 3'd1,
                S_DRAW_WAIT   	   = 3'd2,
                S_ERASE  = 3'd3,
                S_UPDATE_X_Y        = 3'd4;

    always@(*) begin: state_table
        case (curr_state)
            S_INIT: next_state = S_DRAW;
            S_DRAW: next_state = done_draw ? S_DRAW_WAIT : S_DRAW;
            S_DRAW_WAIT: next_state = (go && update_frame) ? S_ERASE : S_DRAW_WAIT;
            S_ERASE: next_state = done_draw ? S_UPDATE_X_Y : S_ERASE;
            S_UPDATE_X_Y: next_state = S_DRAW;

            default: next_state = S_INIT;
        endcase
    end // state_table

    always@(*) begin: enable_signals
        o_draw = 1'b0;
        o_sel_black = 1'b0;
        o_update_x_y = 1'b0;
        o_en_counter = 1'b0;
        case (curr_state) 
            S_DRAW: begin
                o_draw = 1'b1;
                o_sel_black = 1'b0;
                o_update_x_y = 1'b0;
                o_en_counter = 1'b0;
            end
            S_ERASE: begin
                o_draw = 1'b1;
                o_sel_black = 1'b1;
                o_update_x_y = 1'b0;
                o_en_counter = 1'b0;
            end
            S_UPDATE_X_Y: begin
                o_draw = 1'b0;
                o_sel_black = 1'b0;
                o_update_x_y = 1'b1;
                o_en_counter = 1'b0;
            end

    // current_state registers
	always@(posedge clk)
	begin: state_FFs
    	if(!resetn)
        	curr_state <= S_INIT;
    	else
        	curr_state <= next_state;
	end // state_FFS
endmodule 

module datapath (input clk, resetn, en_draw, sel_black,
    input [7:0] xin, input [6:0] yin,
    output reg[7:0] xout, output reg[6:0] yout, output reg done_draw, output reg[2:0] colour_out);
endmodule

// draw sprite
module draw_square (input clk, resetn, enable, 
input[7:0] xin,
input[6:0] yin,
input sel_black, 
output [7:0] x_out, 
output [6:0] y_out,
output [2:0] colour_out,
output reg done_draw);
reg[5:0] counter;

always@(posedge clk) begin
    if (~reset_n) begin
        counter <= 6'b0;
    end
    else if (enable) begin
        if (counter <= 6'b111111)
            x_out<= xin + counter[2:0];
            y_out<=yin + counter[5:3];
            counter<= counter + 1;
        end
        else begin
            x_out <= x_out;
            y_out <= y_out;
        end
    end
    else begin
        x_out <= x_out;
        y_out <= y_out;
    end

end

always@(posedge clk) begin
    if (sel_black) colour_out <= 3'b000;
    else colour_out <= 1'b110;
end
endmodule

// update x y position of sprite
module update_x_y(input reset_n, done_erase, 
input [7:0] xin, 
input [6:0]yin, 
input left, right, up, down, stop,
output reg[7:0] xout, output [6:0] yout);
    always@(*) begin
        if (~reset_n) begin
            xout <= 8'b0;
            yout <= 7'b0;
        end
        else begin
            if (done_erase) begin
                if (stop) begin
                    xout <= xin;
                end
                else if (right) begin
                    xout <= xin + 1;
                end
                else if (left) begin
                    xout <= xin - 1;
                end
                else if (up) begin
                    yout <= yin - 1;
                end
                else if (down) begin
                    yout <= yin + 1;
                end
        end


module RateDivider_4HZ(CLOCK_50, resetn, CLOCK_4HZ);

	input CLOCK_50, resetn;
	output CLOCK_4HZ;
	
	reg CLOCK_4HZ;
	reg [23:0] counter;

	always @(posedge CLOCK_50, negedge resetn) begin
		if (!resetn) begin
			counter <= 24'd0;
			CLOCK_4HZ <= 1'b0;
		end
		else begin
			counter <= (counter == 24'd12499999) ? 0 : counter + 1'b1;
			CLOCK_4HZ <= (counter == 24'd12499999);
		end
	end

endmodule