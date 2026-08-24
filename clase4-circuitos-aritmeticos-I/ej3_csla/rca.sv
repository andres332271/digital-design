`timescale 1ns/1ps
`default_nettype none

module rca #(
    parameter int  N  = 8,
    parameter time TG = 1ns
) (
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    input  wire         cin,
    output wire [N-1:0] s,
    output wire         cout
);

    // Cadena de acarreo: c[0] = cin, c[N] = cout
    wire [N:0] c;

    assign c[0] = cin;
    assign cout = c[N];
    
    genvar i;
    generate
        for (i = 0; i < N; i++) begin : g_fa
            full_adder #(.TG(TG)) u_fa (
                .a    (a[i]),
                .b    (b[i]),
                .cin  (c[i]),
                .s    (s[i]),
                .cout (c[i+1])
            );
        end
    endgenerate

endmodule

`default_nettype wire