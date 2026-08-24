`timescale 1ns/1ps
`default_nettype none

module rca4 #(
    parameter time TG = 1ns
) (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] s,
    output wire       cout
);

    wire [4:0] c;

    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : g_fa
            full_adder #(.TG(TG)) u_fa (
                .a    (a[i]),
                .b    (b[i]),
                .cin  (c[i]),
                .s    (s[i]),
                .cout (c[i+1])
            );
        end
    endgenerate

    assign cout = c[4];

endmodule

`default_nettype wire