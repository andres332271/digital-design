`timescale 1ns/1ps
module reg_ce #(
    parameter WIDTH = 8
)(
    input logic clk,
    input logic rst_n, // reset activo en 0
    input logic ce, // clock enable
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
    q <= 8'h00;
    else if (ce)
    q <= d;
end

endmodule

