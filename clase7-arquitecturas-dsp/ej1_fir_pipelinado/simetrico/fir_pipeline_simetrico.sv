`timescale 1ns/1ps
`default_nettype none

// FIR de 4 taps explotando la simetria h0=h3, h1=h2 (coeficientes {1,3,3,1}):
// pre-suma antes de multiplicar, 2 multiplicadores en vez de 4. Pipelinado y
// retimeado a 3 etapas para el T_cp minimo (2 tu) -- ver report/contenido.tex,
// Punto B "Variante simetrica", y report/figuras/pipeline_simetrico.tex.
//
// Etapa 1: P0=x[n]+x[n-3], P1=x[n-1]+x[n-2], registrados.
// Etapa 2: M0=h0*P0, M1=h1*P1, registrados.
// Etapa 3: A=M0+M1 -> salida registrada.
//
// A diferencia de la cadena, no hace falta ningun registro de alineacion:
// las dos ramas (P0->M0 y P1->M1) son simetricas y avanzan parejas.
//
// Streaming puro (sin FSM): una senal `valid` viaja con los datos por las 3
// etapas. Reset SINCRONO activo en alto, como pide el enunciado (punto C).
module fir_pipeline_simetrico #(
    parameter int DATA_W = 8,
    parameter int N      = 4,
    parameter int ACC_W  = 2*DATA_W + $clog2(N)
) (
    input  logic                     clk,
    input  logic                     rst,       // sincrono, activo en alto
    input  logic                     valid_in,
    input  logic signed [DATA_W-1:0] x_in,
    output logic signed [ACC_W-1:0]  y,
    output logic                     valid_out
);

    // Coeficientes ya folded por simetria: h0(=h3)=1, h1(=h2)=3.
    localparam signed [DATA_W-1:0] H0 = 8'sd1;
    localparam signed [DATA_W-1:0] H1 = 8'sd3;

    // Linea de retardo: taps[0]=x[n-1] ... taps[2]=x[n-3] (x[n] es x_in directo).
    logic signed [DATA_W-1:0] taps [0:N-2];

    // --- Etapa 1: pre-sumas P0=x[n]+x[n-3], P1=x[n-1]+x[n-2], registradas ---
    logic signed [DATA_W:0] p0_r, p1_r;
    logic                   valid_s1;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < N-1; i++) taps[i] <= '0;
            p0_r <= '0; p1_r <= '0;
            valid_s1 <= 1'b0;
        end else begin
            if (valid_in) begin
                for (int i = N-2; i > 0; i--) taps[i] <= taps[i-1];
                taps[0] <= x_in;
            end
            // Pre-sumas sobre la ventana ANTES del shift de este ciclo.
            p0_r <= {x_in[DATA_W-1], x_in} + {taps[2][DATA_W-1], taps[2]};
            p1_r <= {taps[0][DATA_W-1], taps[0]} + {taps[1][DATA_W-1], taps[1]};
            valid_s1 <= valid_in;
        end
    end

    // --- Etapa 2: multiplicadores M0=h0*P0, M1=h1*P1, registrados ---
    logic signed [2*DATA_W:0] m0_r, m1_r;
    logic                     valid_s2;

    always_ff @(posedge clk) begin
        if (rst) begin
            m0_r <= '0; m1_r <= '0; valid_s2 <= 1'b0;
        end else begin
            m0_r <= H0 * p0_r;
            m1_r <= H1 * p1_r;
            valid_s2 <= valid_s1;
        end
    end

    // --- Etapa 3: A=M0+M1 -> salida registrada ---
    logic signed [ACC_W-1:0] a;

    assign a = ACC_W'(m0_r) + ACC_W'(m1_r);

    always_ff @(posedge clk) begin
        if (rst) begin
            y <= '0; valid_out <= 1'b0;
        end else begin
            y         <= a;
            valid_out <= valid_s2;
        end
    end

endmodule

`default_nettype wire
