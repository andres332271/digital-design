`timescale 1ns/1ps
`default_nettype none

// FIR forma directa, version iterativa: 1 multiplicador + 1 sumador compartidos
// (folding total del DFG de ej1_dfg_fir4 sobre N=4 ciclos). La FSM (control_fsm)
// secuencia un producto-y-suma por ciclo sobre la linea de retardo taps[0..N-1].
module fir_iter #(
    parameter int N      = 4,                      // coeficientes/taps
    parameter int DATA_W = 8,                       // ancho de x[n] y de los coeficientes
    parameter int ACC_W  = 2*DATA_W + $clog2(N)      // guard bits: suma de N productos con signo
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     start,
    input  logic signed [DATA_W-1:0] x_in,
    output logic signed [ACC_W-1:0]  y,
    output logic                     done,
    output logic                     busy
);

    // Coeficientes del FIR, forma directa, fijos en tiempo de elaboracion.
    // Nota: Icarus no soporta localparam de array unpacked (ver run.sh) -> case en su lugar.
    function automatic logic signed [DATA_W-1:0] coef(input logic [$clog2(N)-1:0] i);
        case (i)
            2'd0: coef = 8'sd17;
            2'd1: coef = -8'sd23;
            2'd2: coef = 8'sd41;
            2'd3: coef = -8'sd5;
            default: coef = '0;
        endcase
    endfunction

    logic load, mac;
    logic [$clog2(N)-1:0] idx;

    control_fsm #(.N(N)) fsm (
        .clk   (clk),
        .rst_n (rst_n),
        .start (start),
        .load  (load),
        .mac   (mac),
        .done  (done),
        .busy  (busy),
        .idx   (idx)
    );

    // Linea de retardo: taps[0] = x[n] (mas nuevo) ... taps[N-1] = x[n-(N-1)].
    logic signed [DATA_W-1:0]   taps [0:N-1];
    logic signed [ACC_W-1:0]    acc;
    logic signed [2*DATA_W-1:0] prod;

    // Multiplicador y sumador compartidos: un unico producto+suma por ciclo de mac.
    assign prod = coef(idx) * taps[idx];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < N; i++) taps[i] <= '0;
            acc <= '0;
        end else if (load) begin
            for (int i = N-1; i > 0; i--) taps[i] <= taps[i-1];
            taps[0] <= x_in;
            acc     <= '0;
        end else if (mac) begin
            acc <= acc + ACC_W'(prod);
        end
    end

    assign y = acc;

endmodule

`default_nettype wire
