/*
*   Ejercicio 6. Encontrar el latch oculto.
*   alu_bad.v - version con latch oculto.
*/

`timescale 1ns / 1ps

module alu_fix1 (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [1:0] op,
    output reg   [7:0] y
);

  always_comb begin
    case (op)
      2'b00:   y = a + b;
      2'b01:   y = a - b;
      2'b10:   y = a & b;
      default: y = 8'd0;
    endcase
  end

endmodule
