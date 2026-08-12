`timescale 1ns/1ps
`default_nettype none

module rns_multiplicacion_modular
    import rns_pkg::*;
(
    input  logic [WBIN-1:0] x,
    input  logic [WBIN-1:0] y,
    output logic [WBIN-1:0] z,

    // Residuos expuestos para observabilidad en simulacion
    output logic [W1-1:0]   xr1,
    output logic [W2-1:0]   xr2,
    output logic [W3-1:0]   xr3,
    output logic [W1-1:0]   yr1,
    output logic [W2-1:0]   yr2,
    output logic [W3-1:0]   yr3,
    output logic [W1-1:0]   zr1,
    output logic [W2-1:0]   zr2,
    output logic [W3-1:0]   zr3
);

    // Conversion de ambos operandos, en paralelo
    bin_to_rns u_conv_x (
        .valor (x),
        .r1    (xr1),
        .r2    (xr2),
        .r3    (xr3)
    );

    bin_to_rns u_conv_y (
        .valor (y),
        .r1    (yr1),
        .r2    (yr2),
        .r3    (yr3)
    );

    // Producto residuo a residuo
    rns_mult_core u_core (
        .a1 (xr1), .b1 (yr1),
        .a2 (xr2), .b2 (yr2),
        .a3 (xr3), .b3 (yr3),
        .c1 (zr1), .c2 (zr2), .c3 (zr3)
    );

    // Reconstruccion
    rns_to_bin u_conv_z (
        .r1    (zr1),
        .r2    (zr2),
        .r3    (zr3),
        .valor (z)
    );

endmodule

`default_nettype wire