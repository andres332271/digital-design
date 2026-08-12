//   mult_K23_bin        Y = (X<<4) + (X<<2) + (X<<1) + X    -> 4 terminos
`timescale 1ns/1ps
`default_nettype none

//------------------------------------------------------------------------------
// Forma binaria estandar: cuatro terminos no nulos, tres sumadores.
// K = 2^4 + 2^2 + 2^1 + 2^0
//------------------------------------------------------------------------------
module mult_K23_bin #(
    parameter int WIDTH = 8
) (
    input  wire signed [WIDTH-1:0] x,
    output wire signed [WIDTH+4:0] y
);

    localparam int OUTW = WIDTH + 5;

    wire signed [OUTW-1:0] xe = OUTW'(x);   // extension de signo

    assign y = (xe <<< 4) + (xe <<< 2) + (xe <<< 1) + xe;

endmodule

`default_nettype wire