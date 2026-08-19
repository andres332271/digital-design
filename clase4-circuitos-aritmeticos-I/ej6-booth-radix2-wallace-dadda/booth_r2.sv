`timescale 1ns/1ps
`default_nettype none

// Multiplicador Booth radix-2 signado (C2), combinacional. Genera N partial
// products (una por bit de b, con b[-1]=0) segun la tabla clasica:
//   {b[i],b[i-1]} = 00 o 11 -> 0
//   {b[i],b[i-1]} = 01      -> +A
//   {b[i],b[i-1]} = 10      -> -A
// Cada PP se sign-extiende a 2N bits antes de desplazarse y sumarse: la
// aritmetica modular en complemento a 2 garantiza el resultado correcto
// aunque una PP individual "se salga" del rango, porque el producto final
// siempre entra en 2N bits para operandos de N bits.
module booth_r2 #(
    parameter int N = 8
) (
    input  logic signed [N-1:0]   a,
    input  logic signed [N-1:0]   b,
    output logic signed [2*N-1:0] product
);

    localparam int W = 2*N;

    logic signed [W-1:0] a_ext;
    assign a_ext = W'(a);

    logic signed [W-1:0] pp [0:N-1];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_pp
            logic bit_prev;
            logic [1:0] code;
            logic signed [W-1:0] pp_val;

            if (gi == 0) begin : g_b_1
                assign bit_prev = 1'b0;
            end else begin : g_bprev
                assign bit_prev = b[gi-1];
            end
            assign code = {b[gi], bit_prev};

            always_comb begin
                case (code)
                    2'b01:   pp_val = a_ext;
                    2'b10:   pp_val = -a_ext;
                    default: pp_val = '0;
                endcase
            end

            assign pp[gi] = pp_val <<< gi;
        end
    endgenerate

    always_comb begin
        logic signed [W-1:0] acc;
        acc = '0;
        for (int k = 0; k < N; k++) acc = acc + pp[k];
        product = acc;
    end

endmodule

`default_nettype wire
