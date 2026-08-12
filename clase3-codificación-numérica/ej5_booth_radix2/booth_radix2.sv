`timescale 1ns/1ps
`default_nettype none

module booth_radix2 #(
    parameter int N = 4
) (
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   start,
    input  logic signed [N-1:0]    multiplicando,   // A
    input  logic signed [N-1:0]    multiplicador,   // B
    output logic signed [2*N-1:0]  product,
    output logic                   done,
    output logic                   busy
);

    localparam int ACCW = N + 1;            
    localparam int CNTW = $clog2(N) + 1;


    typedef enum logic [1:0] {
        S_IDLE,     // espera de 'start'
        S_CALC,     // N iteraciones del algoritmo
        S_DONE      // resultado valido
    } estado_t;

    estado_t estado, estado_sig;


    logic signed [ACCW-1:0] a_reg;    // acumulador
    logic signed [N-1:0]    q_reg;    // multiplicador, se desplaza
    logic                   q_1;      // bit auxiliar b_{-1}
    logic signed [ACCW-1:0] m_reg;    // multiplicando latcheado y extendido
    logic        [CNTW-1:0] ciclo;    // contador de iteraciones


    logic signed [ACCW-1:0] a_op;
    logic        [1:0]      par;

    assign par = {q_reg[0], q_1};

    always_comb begin
        case (par)
            2'b10:   a_op = a_reg - m_reg;    // restar
            2'b01:   a_op = a_reg + m_reg;    // sumar
            default: a_op = a_reg;            // 00 y 11: sin operacion
        endcase
    end


    always_comb begin
        estado_sig = estado;
        case (estado)
            S_IDLE:  if (start)                estado_sig = S_CALC;
            S_CALC:  if (ciclo == CNTW'(N-1))  estado_sig = S_DONE;
            S_DONE:                            estado_sig = S_IDLE;
            default:                           estado_sig = S_IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) estado <= S_IDLE;
        else        estado <= estado_sig;
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= '0;
            q_reg <= '0;
            q_1   <= 1'b0;
            m_reg <= '0;
            ciclo <= '0;
        end else begin
            case (estado)

                S_IDLE: begin
                    if (start) begin
                        a_reg <= '0;
                        q_reg <= multiplicador;
                        q_1   <= 1'b0;                     // b_{-1} = 0
                        m_reg <= ACCW'(multiplicando);     // extension de signo
                        ciclo <= '0;
                    end
                end

                S_CALC: begin
                    // Desplazamiento aritmetico a derecha de [a_op : q_reg : q_1].
                    // El bit de signo de a_op se replica en la posicion superior.
                    a_reg <= {a_op[ACCW-1], a_op[ACCW-1:1]};
                    q_reg <= {a_op[0],      q_reg[N-1:1]};
                    q_1   <= q_reg[0];
                    ciclo <= ciclo + CNTW'(1);
                end

                default: ;   // S_DONE no modifica el camino de datos

            endcase
        end
    end

    logic [ACCW+N-1:0] concat_aq;

    assign concat_aq = {a_reg, q_reg};

    assign product = concat_aq[2*N-1:0];
    assign done    = (estado == S_DONE);
    assign busy    = (estado == S_CALC);

endmodule

`default_nettype wire