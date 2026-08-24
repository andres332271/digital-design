`timescale 1ns/1ps
`default_nettype none

module cla4 #(
    parameter time TG = 1ns
) (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] s,
    output wire       cout,
    output wire       pg,      // propagate de bloque
    output wire       gg       // generate de bloque
);

    wire [3:0] g, p;
    wire [3:0] c;              // c[0] = cin, c[i] = acarreo hacia el bit i

    //--------------------------------------------------------------------------
    // Nivel 1: generate y propagate por bit
    //--------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : g_gp
            and #(TG) u_g (g[i], a[i], b[i]);
            xor #(TG) u_p (p[i], a[i], b[i]);
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Nivel 2: acarreos en paralelo (AND-OR de dos niveles)
    //--------------------------------------------------------------------------
    assign c[0] = cin;

    // c1 = g0 + p0.c0
    wire t10;
    and #(TG) u_t10 (t10, p[0], c[0]);
    or  #(TG) u_c1  (c[1], g[0], t10);

    // c2 = g1 + p1.g0 + p1.p0.c0
    wire t20, t21;
    and #(TG) u_t20 (t20, p[1], g[0]);
    and #(TG) u_t21 (t21, p[1], p[0], c[0]);
    or  #(TG) u_c2  (c[2], g[1], t20, t21);

    // c3 = g2 + p2.g1 + p2.p1.g0 + p2.p1.p0.c0
    wire t30, t31, t32;
    and #(TG) u_t30 (t30, p[2], g[1]);
    and #(TG) u_t31 (t31, p[2], p[1], g[0]);
    and #(TG) u_t32 (t32, p[2], p[1], p[0], c[0]);
    or  #(TG) u_c3  (c[3], g[2], t30, t31, t32);

    // c4 = g3 + p3.g2 + p3.p2.g1 + p3.p2.p1.g0 + p3.p2.p1.p0.c0
    wire t40, t41, t42, t43;
    and #(TG) u_t40 (t40, p[3], g[2]);
    and #(TG) u_t41 (t41, p[3], p[2], g[1]);
    and #(TG) u_t42 (t42, p[3], p[2], p[1], g[0]);
    and #(TG) u_t43 (t43, p[3], p[2], p[1], p[0], c[0]);
    or  #(TG) u_c4  (cout, g[3], t40, t41, t42, t43);

    //--------------------------------------------------------------------------
    // Nivel 3: bits de suma
    //--------------------------------------------------------------------------
    generate
        for (i = 0; i < 4; i++) begin : g_sum
            xor #(TG) u_s (s[i], p[i], c[i]);
        end
    endgenerate

    and #(TG) u_pg (pg, p[3], p[2], p[1], p[0]);

    wire q0, q1, q2;
    and #(TG) u_q0 (q0, p[3], g[2]);
    and #(TG) u_q1 (q1, p[3], p[2], g[1]);
    and #(TG) u_q2 (q2, p[3], p[2], p[1], g[0]);
    or  #(TG) u_gg (gg, g[3], q0, q1, q2);

endmodule

`default_nettype wire