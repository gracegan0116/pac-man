module mux_vga (MuxSelect, x_pacman, y_pacman, colour_pacman, x_bg, y_bg, coulour_bg, out);
    input [7:0] x_pacman, x_bg;
    input [6:0] y_pacman, y_bg;
    input colour_pacman, coulour_bg;
    input[2:0] MuxSelect;

    output reg[15:0] out;

    always@(*)
    begin
        case(MuxSelect[2:0])
            3'b000: out = {x_bg,y_bg,coulour_bg};
            3'b001: out = {x_pacman,y_pacman,colour_pacman};
            default: out = 0;
        endcase
    end
endmodule
