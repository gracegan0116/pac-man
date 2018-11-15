module draw_pacman_left (reset, writeEn, x, y, startx, starty, clock, colour, done_print);
    input clock;
    input writeEn;
    input reset;
    input [7:0] startx;
    input [6:0] starty;
    output [7:0] x;
    output [6:0] y;
    output reg done_print;
    output colour;

    wire[6:0] address;
    reg[7:0] count_x = 0;
    reg[6:0] count_y = 0;

    pacman_left_small pacman(
        .address(address),
        .clock(clock),
        .q(colour)
    );

    reg[4:0] addr_x = 0;
    reg[4:0] addr_y = 0;
    always@(posedge clock) begin

        if (~reset) begin
            addr_x = 0;
            addr_y = 0;
            count_x = 0;
            count_y = 0;
        end

        else if (writeEn) begin
            done_print = 0;
            if (addr_x != 5) begin
                count_x = count_x + 1'b1;
                addr_x = addr_x + 1'b1;
            end
            else begin
                addr_y = addr_y + 1'b1;
                count_y = count_y + 1'b1;
                addr_x = 0;
                count_x = 0;
                if (addr_y == 5) begin
                    count_y = 0;
                    addr_y = 0;
                    done_print = 1;
                end
            end

        end
    end

    assign address = addr_x + 5 * (addr_y);
    assign x = count_x + startx;
    assign y = count_y + starty;
endmodule

