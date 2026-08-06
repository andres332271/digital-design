/*
*   Ejercicio 6. Encontrar el latch oculto.
*   alu_fix2.v - fix por pre-asignación: y se inicializa antes del case,
*   así toda rama no cubierta (op=2'b11) queda con un valor definido.
*/

`timescale 1ns / 1ps

module alu_fix2 (
    input logic signed [7:0] a,
    input logic signed [7:0] b,
    input logic [1:0] op,
    output reg signed [7:0] y
);

  always_comb begin
    y = 8'sd0; // pre-asignación: valor por defecto antes del case
    case (op)
      2'b00: y = a + b;
      2'b01: y = a - b;
      2'b10: y = a & b;
    endcase
  end

endmodule
