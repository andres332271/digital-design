`timescale 1ns/1ps
`default_nettype none

// Suma A + B con distinto formato S(NB, NBF) cada uno.
// Regla de la consigna: NBF_out = max(NBFA, NBFB); NBI_out = max(NBIA, NBIB) + 1.
module sumador_punto_fijo #(
    parameter int NBA  = 6,
    parameter int NBFA = 4,
    parameter int NBB  = 8,
    parameter int NBFB = 5,
    localparam int NBIA = NBA - NBFA,
    localparam int NBIB = NBB - NBFB,
    localparam int NBFS = (NBFA > NBFB) ? NBFA : NBFB,
    localparam int NBIS = ((NBIA > NBIB) ? NBIA : NBIB) + 1,
    localparam int NBS  = NBIS + NBFS
) (
    input  wire signed [NBA-1:0] a,
    input  wire signed [NBB-1:0] b,
    output wire signed [NBS-1:0] sum
);

    // Extender signo al ancho final y luego alinear la coma (shift = diferencia de NBF).
    wire signed [NBS-1:0] a_ext = NBS'(a) <<< (NBFS - NBFA);
    wire signed [NBS-1:0] b_ext = NBS'(b) <<< (NBFS - NBFB);

    assign sum = a_ext + b_ext;

endmodule

`default_nettype wire
