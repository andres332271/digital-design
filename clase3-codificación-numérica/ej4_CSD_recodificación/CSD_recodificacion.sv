//   CSD_recodificacion  Y = (X<<5) - (X<<3) - X             -> 3 terminos
`timescale 1ns/1ps
`default_nettype none

//------------------------------------------------------------------------------
// Forma CSD canonica: tres terminos no nulos, dos operadores.
// K = 2^5 - 2^3 - 2^0
//------------------------------------------------------------------------------
module CSD_recodificacion #(
    parameter int WIDTH = 8
) (
    input  wire signed [WIDTH-1:0] x,
    output wire signed [WIDTH+4:0] y
);

    localparam int OUTW = WIDTH + 5;

    wire signed [OUTW-1:0] xe = OUTW'(x);   // extension de signo

    assign y = (xe <<< 5) - (xe <<< 3) - xe;

endmodule

`default_nettype wire