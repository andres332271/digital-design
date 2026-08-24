`timescale 1ns/1ps
`default_nettype none

module cla16 #(
    parameter time TG = 1ns
) (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] s,
    output wire        cout
);

    wire [3:0] pg, gg;         // agregados de cada bloque
    wire [4:1] cblk;           // acarreos de entrada de los bloques 1 a 3, y cout

    //--------------------------------------------------------------------------
    // Segundo nivel de lookahead
    //--------------------------------------------------------------------------
    // C4 = GG0 + PG0.c0
    wire u10;
    and #(TG) g_u10 (u10, pg[0], cin);
    or  #(TG) g_c4  (cblk[1], gg[0], u10);

    // C8 = GG1 + PG1.GG0 + PG1.PG0.c0
    wire u20, u21;
    and #(TG) g_u20 (u20, pg[1], gg[0]);
    and #(TG) g_u21 (u21, pg[1], pg[0], cin);
    or  #(TG) g_c8  (cblk[2], gg[1], u20, u21);

    // C12 = GG2 + PG2.GG1 + PG2.PG1.GG0 + PG2.PG1.PG0.c0
    wire u30, u31, u32;
    and #(TG) g_u30 (u30, pg[2], gg[1]);
    and #(TG) g_u31 (u31, pg[2], pg[1], gg[0]);
    and #(TG) g_u32 (u32, pg[2], pg[1], pg[0], cin);
    or  #(TG) g_c12 (cblk[3], gg[2], u30, u31, u32);

    // C16 = GG3 + PG3.GG2 + PG3.PG2.GG1 + PG3.PG2.PG1.GG0 + PG3.PG2.PG1.PG0.c0
    wire u40, u41, u42, u43;
    and #(TG) g_u40 (u40, pg[3], gg[2]);
    and #(TG) g_u41 (u41, pg[3], pg[2], gg[1]);
    and #(TG) g_u42 (u42, pg[3], pg[2], pg[1], gg[0]);
    and #(TG) g_u43 (u43, pg[3], pg[2], pg[1], pg[0], cin);
    or  #(TG) g_c16 (cblk[4], gg[3], u40, u41, u42, u43);

    assign cout = cblk[4];

    //--------------------------------------------------------------------------
    // Bloques de 4 bits.
    // El cout de cada bloque queda sin conectar: el acarreo que importa es el
    // que calcula el segundo nivel, disponible antes.
    //--------------------------------------------------------------------------
    wire [3:0] cout_blk_nc;

    cla4 #(.TG(TG)) u_blk0 (
        .a (a[3:0]),   .b (b[3:0]),   .cin (cin),
        .s (s[3:0]),   .cout (cout_blk_nc[0]),
        .pg (pg[0]),   .gg (gg[0])
    );

    cla4 #(.TG(TG)) u_blk1 (
        .a (a[7:4]),   .b (b[7:4]),   .cin (cblk[1]),
        .s (s[7:4]),   .cout (cout_blk_nc[1]),
        .pg (pg[1]),   .gg (gg[1])
    );

    cla4 #(.TG(TG)) u_blk2 (
        .a (a[11:8]),  .b (b[11:8]),  .cin (cblk[2]),
        .s (s[11:8]),  .cout (cout_blk_nc[2]),
        .pg (pg[2]),   .gg (gg[2])
    );

    cla4 #(.TG(TG)) u_blk3 (
        .a (a[15:12]), .b (b[15:12]), .cin (cblk[3]),
        .s (s[15:12]), .cout (cout_blk_nc[3]),
        .pg (pg[3]),   .gg (gg[3])
    );

endmodule

`default_nettype wire