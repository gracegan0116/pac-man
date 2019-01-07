module mux_vga (MuxSelect, x_pacman, y_pacman, colour_pacman, x_bg, y_bg, coulour_bg, gameover_x, gameover_y, colour_over, win_x, win_y, colour_win, exit_x, exit_y,exit_colour, out);
    input [7:0] x_pacman, x_bg, gameover_x, win_x, exit_x;
    input [6:0] y_pacman, y_bg, gameover_y, win_y, exit_y;
    input colour_pacman, coulour_bg, colour_over, colour_win, exit_colour;
    input[2:0] MuxSelect;

    output reg[15:0] out;

    always@(*)
    begin
        case(MuxSelect[2:0])
            3'b000: out = {x_bg,y_bg,coulour_bg};
            3'b001: out = {x_pacman,y_pacman,colour_pacman};
				3'b010: out = {win_x, win_y, colour_win};
				3'b011: out = {gameover_x, gameover_y, colour_over};
				3'b100: out = {exit_x, exit_y, exit_colour};
            default: out = 0;
        endcase
    end
endmodule
