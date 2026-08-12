`timescale 1ns/1ps
`default_nettype none

module bin_to_rns
    import rns_pkg::*;
(
    input  logic [WBIN-1:0] valor,
    output logic [W1-1:0]   r1,
    output logic [W2-1:0]   r2,
    output logic [W3-1:0]   r3
);

    assign r1 = W1'(valor % WBIN'(M1));
    assign r2 = W2'(valor % WBIN'(M2));
    assign r3 = W3'(valor % WBIN'(M3));

endmodule

`default_nettype wire