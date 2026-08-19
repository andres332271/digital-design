`timescale 1ns/1ps
`default_nettype none

// Array multiplier NxN unsigned combinacional: matriz de AND para las
// partial products, N-1 filas de reduccion carry-save (full/half adder), y
// una fila final de ripple-carry adder (CPA) que resuelve el ultimo par
// suma/carry en los N bits altos del producto.
module array_mul #(
    parameter int N = 8
) (
    input  logic [N-1:0]   a,
    input  logic [N-1:0]   b,
    output logic [2*N-1:0] product
);

    genvar gi, gj;

    // pp[i][j] = a[j] & b[i]
    logic [N-1:0] pp        [0:N-1];
    logic [N-1:0] sum_row   [0:N-1];
    logic [N-1:0] carry_row [0:N-1];

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_pp_row
            for (gj = 0; gj < N; gj = gj + 1) begin : g_pp_col
                assign pp[gi][gj] = a[gj] & b[gi];
            end
        end
    endgenerate

    // Fila 0: partial products crudas, sin sumar todavia.
    assign sum_row[0]   = pp[0];
    assign carry_row[0] = '0;

    // Filas 1..N-1: reduccion carry-save. Columna N-1 (borde derecho) no
    // tiene entrada diagonal de la fila anterior -> half adder; el resto,
    // full adder. product[i] queda fijo en sum_row[i][0] apenas se calcula.
    generate
        for (gi = 1; gi < N; gi = gi + 1) begin : g_row
            for (gj = 0; gj < N; gj = gj + 1) begin : g_col
                if (gj == N-1) begin : g_ha
                    half_adder ha (
                        .a    (pp[gi][gj]),
                        .b    (carry_row[gi-1][gj]),
                        .sum  (sum_row[gi][gj]),
                        .cout (carry_row[gi][gj])
                    );
                end else begin : g_fa
                    full_adder fa (
                        .a    (pp[gi][gj]),
                        .b    (sum_row[gi-1][gj+1]),
                        .cin  (carry_row[gi-1][gj]),
                        .sum  (sum_row[gi][gj]),
                        .cout (carry_row[gi][gj])
                    );
                end
            end
        end
    endgenerate

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_plow
            assign product[gi] = sum_row[gi][0];
        end
    endgenerate

    // Fila final: CPA (ripple-carry) que suma sum_row[N-1][1..N-1] (relleno
    // con 0 en el bit mas alto) con carry_row[N-1][0..N-1].
    logic [N-1:0] a_final, b_final, s_final;
    logic [N-1:1] c_final;
    logic         final_cout;  // siempre 0: 8x8 unsigned entra en 16 bits

    generate
        for (gj = 0; gj < N-1; gj = gj + 1) begin : g_afinal
            assign a_final[gj] = sum_row[N-1][gj+1];
        end
    endgenerate
    assign a_final[N-1] = 1'b0;
    assign b_final       = carry_row[N-1];

    generate
        for (gj = 0; gj < N; gj = gj + 1) begin : g_final_row
            if (gj == 0) begin : g_final_ha
                half_adder ha_final (
                    .a    (a_final[0]),
                    .b    (b_final[0]),
                    .sum  (s_final[0]),
                    .cout (c_final[1])
                );
            end else if (gj == N-1) begin : g_final_fa_last
                full_adder fa_final (
                    .a    (a_final[gj]),
                    .b    (b_final[gj]),
                    .cin  (c_final[gj]),
                    .sum  (s_final[gj]),
                    .cout (final_cout)
                );
            end else begin : g_final_fa
                full_adder fa_final (
                    .a    (a_final[gj]),
                    .b    (b_final[gj]),
                    .cin  (c_final[gj]),
                    .sum  (s_final[gj]),
                    .cout (c_final[gj+1])
                );
            end
        end
    endgenerate

    assign product[2*N-1:N] = s_final;

endmodule

`default_nettype wire
