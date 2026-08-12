`timescale 1ns/1ps
`default_nettype none

module rns_to_bin
    import rns_pkg::*;
(
    input  logic [W1-1:0]   r1,
    input  logic [W2-1:0]   r2,
    input  logic [W3-1:0]   r3,
    output logic [WBIN-1:0] valor
);

    localparam int ACCW = 9;

    logic [ACCW-1:0] suma;

    assign suma = ACCW'(C1) * ACCW'(r1)
                + ACCW'(C2) * ACCW'(r2)
                + ACCW'(C3) * ACCW'(r3);

    assign valor = WBIN'(suma % ACCW'(M));

endmodule

`default_nettype wire