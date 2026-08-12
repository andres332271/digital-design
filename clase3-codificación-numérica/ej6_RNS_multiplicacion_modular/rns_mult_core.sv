`timescale 1ns/1ps
`default_nettype none

module rns_mult_core
    import rns_pkg::*;
(
    input  logic [W1-1:0] a1, b1,
    input  logic [W2-1:0] a2, b2,
    input  logic [W3-1:0] a3, b3,
    output logic [W1-1:0] c1,
    output logic [W2-1:0] c2,
    output logic [W3-1:0] c3
);

    // Canal modulo 3
    logic [2*W1-1:0] p1;
    assign p1 = a1 * b1;
    assign c1 = W1'(p1 % (2*W1)'(M1));

    // Canal modulo 5
    logic [2*W2-1:0] p2;
    assign p2 = a2 * b2;
    assign c2 = W2'(p2 % (2*W2)'(M2));

    // Canal modulo 7
    logic [2*W3-1:0] p3;
    assign p3 = a3 * b3;
    assign c3 = W3'(p3 % (2*W3)'(M3));

endmodule

`default_nettype wire