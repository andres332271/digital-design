`timescale 1ns/1ps
`default_nettype none

module half_adder (
    input  logic a,
    input  logic b,
    output logic sum,
    output logic cout
);

    assign sum  = a ^ b;
    assign cout = a & b;

endmodule

`default_nettype wire
