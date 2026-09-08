`timescale 1ns/1ps
`default_nettype none

// FSM de control para el FIR iterativo (1 multiplicador + 1 sumador compartidos).
// IDLE: espera start. COMPUTE: N ciclos, 1 producto-y-suma por ciclo. DONE: y valido 1 ciclo.
module control_fsm #(
    parameter int N = 4  // cantidad de coeficientes/taps (= ciclos de compute)
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    output logic load,               // pulso: IDLE -> COMPUTE, shiftea taps y resetea acc
    output logic mac,                // activo durante todo COMPUTE
    output logic done,
    output logic busy,
    output logic [$clog2(N)-1:0] idx // indice de tap/coeficiente valido durante mac
);

    localparam int CNTW = $clog2(N) + 1;

    typedef enum logic [1:0] {
        S_IDLE,
        S_COMPUTE,
        S_DONE
    } estado_t;

    estado_t estado, estado_sig;
    logic [CNTW-1:0] ciclo;

    always_comb begin
        estado_sig = estado;
        case (estado)
            S_IDLE:    if (start)               estado_sig = S_COMPUTE;
            S_COMPUTE: if (ciclo == CNTW'(N-1)) estado_sig = S_DONE;
            S_DONE:                             estado_sig = S_IDLE;
            default:                            estado_sig = S_IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) estado <= S_IDLE;
        else        estado <= estado_sig;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ciclo <= '0;
        end else begin
            case (estado)
                S_IDLE:    ciclo <= '0;
                S_COMPUTE: ciclo <= ciclo + CNTW'(1);
                default:   ciclo <= ciclo;
            endcase
        end
    end

    assign load = (estado == S_IDLE) && start;
    assign mac  = (estado == S_COMPUTE);
    assign done = (estado == S_DONE);
    assign busy = (estado == S_COMPUTE);
    assign idx  = ciclo[$clog2(N)-1:0];

endmodule

`default_nettype wire
