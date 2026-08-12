`timescale 1ns/1ps
`default_nettype none

// Recorta x de S(NBI_IN,NBF_IN) a S(NBI_OUT,NBF_OUT).
// ROUND_EN: 0=trunca hacia cero, 1=redondeo half-to-even
// SAT_EN:   0=wrap (modulo), 1=satura a los extremos
// Se asume NBF_IN >= NBF_OUT (solo se contempla achicar, como pide la consigna).
module recorte_punto_fijo #(
    parameter int NBI_IN  = 10,
    parameter int NBF_IN  = 6,
    parameter int NBI_OUT = 7,
    parameter int NBF_OUT = 3,
    parameter bit ROUND_EN = 0,
    parameter bit SAT_EN   = 0,
    localparam int W_IN  = NBI_IN + NBF_IN,
    localparam int W_OUT = NBI_OUT + NBF_OUT,
    localparam int SHIFT = NBF_IN - NBF_OUT,
    localparam int W_MID = W_IN + 1          // margen: carry de redondeo / negacion en el minimo
) (
    input  wire  signed [W_IN-1:0]  x,
    output logic signed [W_OUT-1:0] y
);

    wire signed [W_MID-1:0] x_ext = W_MID'(x);

    // --- paso 1: ajustar bits fraccionarios (SHIFT bits) ---
    logic signed [W_MID-1:0] resized_frac;

    generate
        if (SHIFT == 0) begin : g_no_shift
            assign resized_frac = x_ext;
        end else if (ROUND_EN) begin : g_round
            // redondeo half-to-even: guard = bit descartado mas significativo,
            // sticky = OR del resto de bits descartados, empate -> par.
            wire                     guard  = x_ext[SHIFT-1];
            wire                     sticky = (SHIFT > 1) ? (|x_ext[SHIFT-2:0]) : 1'b0;
            wire signed [W_MID-1:0]  base   = x_ext >>> SHIFT;
            wire                     round_up = guard & (sticky | base[0]);
            assign resized_frac = base + W_MID'(round_up);
        end else begin : g_trunc
            // truncado hacia cero: se trunca la magnitud, no el piso.
            wire signed [W_MID-1:0] mag = x_ext[W_MID-1] ? -x_ext : x_ext;
            wire signed [W_MID-1:0] mag_trunc = mag >>> SHIFT;
            assign resized_frac = x_ext[W_MID-1] ? -mag_trunc : mag_trunc;
        end
    endgenerate

    // --- paso 2: ajustar rango (bits enteros) ---
    localparam int MAX_OUT = (1 << (W_OUT-1)) - 1;
    localparam int MIN_OUT = -(1 << (W_OUT-1));

    generate
        if (SAT_EN) begin : g_sat
            assign y = (resized_frac > W_MID'(MAX_OUT)) ? W_OUT'(MAX_OUT) :
                       (resized_frac < W_MID'(MIN_OUT)) ? W_OUT'(MIN_OUT) :
                       resized_frac[W_OUT-1:0];
        end else begin : g_wrap
            assign y = resized_frac[W_OUT-1:0];
        end
    endgenerate

endmodule

`default_nettype wire
