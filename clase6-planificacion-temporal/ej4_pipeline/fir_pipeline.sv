`timescale 1ns/1ps
`default_nettype none

// FIR forma directa, version pipeline retimeada (ver report.md): cut-set feed-forward
// entre la etapa de multiplicadores y la de sumas (4 registros de producto), SIN un
// segundo cut-set dentro de la cadena de sumas -- a1, a2 y a3 quedan combinacionales
// en la misma etapa porque su retardo combinado (2 add) empata con el de la etapa de
// multiplicadores (1 mult), asi que partirla no gana fmax, solo agrega latencia.
// Streaming: acepta una muestra nueva por ciclo (valid_in), sin FSM -- el control es
// solo el shift-register de `valid` que sigue a los datos por las 2 etapas.
module fir_pipeline #(
    parameter int N      = 4,
    parameter int DATA_W = 8,
    parameter int ACC_W  = 2*DATA_W + $clog2(N)
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     valid_in,
    input  logic signed [DATA_W-1:0] x_in,
    output logic signed [ACC_W-1:0]  y,
    output logic                     valid_out
);

    // Mismos coeficientes que fir_iter.sv (ver nota de Icarus en ese archivo).
    function automatic logic signed [DATA_W-1:0] coef(input int i);
        case (i)
            0: coef = 8'sd17;
            1: coef = -8'sd23;
            2: coef = 8'sd41;
            3: coef = -8'sd5;
            default: coef = '0;
        endcase
    endfunction

    // Linea de retardo: taps[0] = x[n] (mas nuevo) ... taps[N-1] = x[n-(N-1)].
    logic signed [DATA_W-1:0] taps [0:N-1];

    // --- Etapa 1: 4 multiplicadores en paralelo, registrados (cut-set A) ---
    logic signed [2*DATA_W-1:0] m0_r, m1_r, m2_r, m3_r;
    logic                       valid_s1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < N; i++) taps[i] <= '0;
            m0_r <= '0; m1_r <= '0; m2_r <= '0; m3_r <= '0;
            valid_s1 <= 1'b0;
        end else begin
            if (valid_in) begin
                for (int i = N-1; i > 0; i--) taps[i] <= taps[i-1];
                taps[0] <= x_in;
            end
            // Productos combinacionales sobre la linea de retardo ANTES del shift de
            // este ciclo (m0 usa x_in directo: todavia no paso a ser taps[0]).
            m0_r <= coef(0) * x_in;
            m1_r <= coef(1) * taps[0];
            m2_r <= coef(2) * taps[1];
            m3_r <= coef(3) * taps[2];
            valid_s1 <= valid_in;
        end
    end

    // --- Etapa 2: arbol de sumas combinacional (a1, a2, a3 en la misma etapa -- ---
    //     retiming: no hay registro entre ellas), salida registrada (cut-set A, salida) ---
    logic signed [2*DATA_W:0] a1, a2;
    logic signed [ACC_W-1:0]  a3;

    assign a1 = {m0_r[2*DATA_W-1], m0_r} + {m1_r[2*DATA_W-1], m1_r};
    assign a2 = {m2_r[2*DATA_W-1], m2_r} + {m3_r[2*DATA_W-1], m3_r};
    assign a3 = ACC_W'(a1) + ACC_W'(a2);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y         <= '0;
            valid_out <= 1'b0;
        end else begin
            y         <= a3;
            valid_out <= valid_s1;
        end
    end

endmodule

`default_nettype wire
