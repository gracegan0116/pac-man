module draw_exit (enable, clk, resetn, vga_x, vga_y, colour, done);
    input clk, enable, resetn;
    output [7:0] vga_x;
    output [6:0] vga_y;
    output reg done = 0;
    output colour;

    wire [4:0] address;
    reg [7:0] count_x = 8'b10010100;
    reg [6:0] count_y = 7'b1101110;

    exit exit (
        .address(address),
        .clock(clk),
        .q(colour)
    );

    reg [7:0] addr_x = 0;
    reg [6:0] addr_y = 0;

    always@(posedge clk) 
    begin
        if (~resetn) begin
            addr_x = 0;
            addr_y = 0;
            count_x = 8'b10010100;
            count_y = 7'b1101110;
        end

        else if (enable) begin
            done = 0;
            if (addr_x != 5) begin
                count_x = count_x + 1'b1;
                addr_x = addr_x + 1'b1;
            end
            else begin  
                addr_y = addr_y + 1'b1;
                count_y = count_y + 1'b1;
                addr_x = 0;
                count_x = 8'b10010100;
                if (addr_y == 5) begin
                    count_y = 7'b1101110;
                    addr_y = 0;
                    done = 1;
                end
            end
        end
    end

    assign address = addr_x + 5*(addr_y);
    assign vga_x = count_x;
    assign vga_y = count_y;
endmodule

