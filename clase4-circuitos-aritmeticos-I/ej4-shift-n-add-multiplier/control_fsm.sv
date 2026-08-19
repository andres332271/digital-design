`timescale 1ns/1ps
`default_nettype none

// FSM de control para el multiplicador secuencial shift-and-add.
// IDLE: espera start. COMPUTE: N ciclos de shift+add. DONE: resultado valido un ciclo.
module control_fsm #(
    parameter int N = 8
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    output logic load,       // pulso: cargar operandos (IDLE -> COMPUTE)
    output logic shift_add,  // activo durante todo COMPUTE
    output logic done,
    output logic busy
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

    assign load      = (estado == S_IDLE) && start;
    assign shift_add = (estado == S_COMPUTE);
    assign done      = (estado == S_DONE);
    assign busy      = (estado == S_COMPUTE);

endmodule

`default_nettype wire
