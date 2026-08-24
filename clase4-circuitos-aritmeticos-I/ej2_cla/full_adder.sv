// Suma tres bits (a, b, cin) produciendo suma y acarreo de salida:
//
//     s    = a XOR b XOR cin
//     cout = a.b + cin.(a XOR b)
`timescale 1ns/1ps
`default_nettype none

module full_adder #(
    parameter time TG = 1ns          // retardo de un nivel de logica
) (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire s,
    output wire cout
);

    wire p;        // propagate: a XOR b
    wire g;        // generate:  a AND b
    wire pc;       // p AND cin

    xor #(TG) u_xor_p    (p,    a, b); // p = a XOR b
    xor #(TG) u_xor_s    (s,    p, cin); // s = p XOR cin
    and #(TG) u_and_g    (g,    a, b); // g = a AND b
    and #(TG) u_and_pc   (pc,   p, cin); // pc = p AND cin
    or  #(TG) u_or_cout  (cout, g, pc); // cout = g OR pc

endmodule

`default_nettype wire