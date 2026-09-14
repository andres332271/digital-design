`timescale 1ns/1ps
`default_nettype none

// FIR de 4 taps, forma directa en cadena (sin explotar la simetria de los
// coeficientes), pipelinado y retimeado a 3 etapas para llegar al T_cp minimo
// real (2 tu, acotado por el multiplicador) -- ver report/contenido.tex,
// Punto B "Cadena generica", y report/figuras/pipeline_cadena.tex.
//
// Etapa 1: 4 multiplicadores en paralelo, registrados (corte tras los mults).
// Etapa 2: a1=m0+m1, a2=a1+m2 combinacionales (caben en el mismo periodo que
//          un multiplicador); m3 no se usa aca, asi que se re-registra sin
//          modificar (registro de alineacion) para no desincronizarse.
// Etapa 3: a3=a2+m3 -> salida registrada.
//
// Streaming puro (sin FSM): una senal `valid` viaja con los datos por las 3
// etapas. Reset SINCRONO activo en alto, como pide el enunciado (punto C).
module fir_pipeline_cadena #(
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

    // Coeficientes del enunciado: {h0,h1,h2,h3} = {1,3,3,1}.
    function automatic logic signed [DATA_W-1:0] coef(input int i);
        case (i)
            0: coef = 8'sd1;
            1: coef = 8'sd3;
            2: coef = 8'sd3;
            3: coef = 8'sd1;
            default: coef = '0;
        endcase
    endfunction

    // Linea de retardo: taps[0]=x[n-1] ... taps[2]=x[n-3] (x[n] es x_in directo).
    logic signed [DATA_W-1:0] taps [0:N-2];

    // --- Etapa 1: multiplicadores, registrados ---
    logic signed [2*DATA_W-1:0] m0_r, m1_r, m2_r, m3_r;
    logic                       valid_s1;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < N-1; i++) taps[i] <= '0;
            m0_r <= '0; m1_r <= '0; m2_r <= '0; m3_r <= '0;
            valid_s1 <= 1'b0;
        end else begin
            if (valid_in) begin
                for (int i = N-2; i > 0; i--) taps[i] <= taps[i-1];
                taps[0] <= x_in;
            end
            // Productos sobre la ventana ANTES del shift de este ciclo.
            m0_r <= coef(0) * x_in;
            m1_r <= coef(1) * taps[0];
            m2_r <= coef(2) * taps[1];
            m3_r <= coef(3) * taps[2];
            valid_s1 <= valid_in;
        end
    end

    // --- Etapa 2: a1=m0+m1, a2=a1+m2 combinacionales; m3 se re-registra ---
    logic signed [2*DATA_W:0] a1;
    logic signed [ACC_W-1:0]  a2;
    logic signed [ACC_W-1:0]  a2_r;
    logic signed [2*DATA_W-1:0] m3_r2;
    logic                       valid_s2;

    assign a1 = {m0_r[2*DATA_W-1], m0_r} + {m1_r[2*DATA_W-1], m1_r};
    assign a2 = ACC_W'(a1) + ACC_W'(m2_r);

    always_ff @(posedge clk) begin
        if (rst) begin
            a2_r <= '0; m3_r2 <= '0; valid_s2 <= 1'b0;
        end else begin
            a2_r  <= a2;
            m3_r2 <= m3_r;   // registro de alineacion: m3 no se usa en esta etapa
            valid_s2 <= valid_s1;
        end
    end

    // --- Etapa 3: a3=a2+m3 -> salida registrada ---
    logic signed [ACC_W-1:0] a3;

    assign a3 = a2_r + ACC_W'(m3_r2);

    always_ff @(posedge clk) begin
        if (rst) begin
            y <= '0; valid_out <= 1'b0;
        end else begin
            y         <= a3;
            valid_out <= valid_s2;
        end
    end

endmodule

`default_nettype wire
