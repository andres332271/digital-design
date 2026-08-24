`timescale 1ns/1ps
`default_nettype none

module csla16 #(
    parameter time TG = 1ns
) (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] s,
    output wire        cout
);


    wire [3:1] carry;          // acarreo real de entrada a los bloques 1, 2 y 3

    rca4 #(.TG(TG)) u_blk0 (
        .a (a[3:0]), .b (b[3:0]), .cin (cin),
        .s (s[3:0]), .cout (carry[1])
    );


    genvar k;
    generate
        for (k = 1; k <= 3; k++) begin : g_blk

            localparam int LSB = 4 * k;

            wire [3:0] s0, s1;
            wire       c0, c1;
            wire       sel;

            // sel es el acarreo real que llega del bloque anterior
            assign sel = carry[k];

            rca4 #(.TG(TG)) u_add0 (
                .a (a[LSB+3:LSB]), .b (b[LSB+3:LSB]), .cin (1'b0),
                .s (s0), .cout (c0)
            );

            rca4 #(.TG(TG)) u_add1 (
                .a (a[LSB+3:LSB]), .b (b[LSB+3:LSB]), .cin (1'b1),
                .s (s1), .cout (c1)
            );

            // Seleccion de los cuatro bits de suma
            mux2 #(.TG(TG)) u_ms0 (.d0(s0[0]), .d1(s1[0]), .sel(sel), .y(s[LSB+0]));
            mux2 #(.TG(TG)) u_ms1 (.d0(s0[1]), .d1(s1[1]), .sel(sel), .y(s[LSB+1]));
            mux2 #(.TG(TG)) u_ms2 (.d0(s0[2]), .d1(s1[2]), .sel(sel), .y(s[LSB+2]));
            mux2 #(.TG(TG)) u_ms3 (.d0(s0[3]), .d1(s1[3]), .sel(sel), .y(s[LSB+3]));

            // Seleccion del acarreo de salida del bloque
            if (k < 3) begin : g_carry_mid
                mux2 #(.TG(TG)) u_mc (.d0(c0), .d1(c1), .sel(sel), .y(carry[k+1]));
            end else begin : g_carry_last
                mux2 #(.TG(TG)) u_mc (.d0(c0), .d1(c1), .sel(sel), .y(cout));
            end

        end
    endgenerate

endmodule

module mux2 #(
    parameter time TG = 1ns
) (
    input  wire d0,
    input  wire d1,
    input  wire sel,
    output wire y
);

    wire nsel, t0, t1;

    not #(TG) u_not (nsel, sel);
    and #(TG) u_a0  (t0, d0, nsel);
    and #(TG) u_a1  (t1, d1, sel);
    or  #(TG) u_or  (y,  t0, t1);

endmodule

`default_nettype wire