`timescale 1ns/1ps
module bcd_counter 
#(
    parameter MAX_COUNT=9
)
(
    input logic clk,
    input logic rst, 
    input logic en, 
    output logic [3:0] cnt,
    output logic tc
);

always_ff @(posedge clk) begin
    if (rst) begin
    cnt <= 4'd0;
    end else if (en) begin
    cnt <= (cnt == MAX_COUNT) ? 0 : cnt + 1;
    end
end

assign tc = (cnt == MAX_COUNT) && en;

endmodule