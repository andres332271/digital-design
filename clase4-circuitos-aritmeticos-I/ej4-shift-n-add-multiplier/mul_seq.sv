`timescale 1ns/1ps
`default_nettype none

// Multiplicador secuencial unsigned NxN -> 2N, shift-and-add ("add then
// shift-right"). acc concatena {suma_parcial[N:0] , b_pendiente[N-2:0]}:
// el shift ocurre al reasignar acc con esa concatenacion, sin paso aparte.
// Un unico adder de N bits (con carry) se reusa en cada uno de los N ciclos.
module mul_seq #(
    parameter int N = 8
) (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic [N-1:0] a,
    input  logic [N-1:0] b,
    output logic [2*N-1:0] product,
    output logic          done,
    output logic          busy
);

    logic load, shift_add;

    control_fsm #(.N(N)) fsm (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .load      (load),
        .shift_add (shift_add),
        .done      (done),
        .busy      (busy)
    );

    logic [N-1:0]   a_reg;
    logic [2*N-1:0] acc;
    logic [N:0]     suma;

    assign suma = {1'b0, acc[2*N-1:N]} + (acc[0] ? {1'b0, a_reg} : '0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= '0;
            acc   <= '0;
        end else if (load) begin
            a_reg <= a;
            acc   <= {{N{1'b0}}, b};
        end else if (shift_add) begin
            acc <= {suma, acc[N-1:1]};
        end
    end

    assign product = acc;

endmodule

`default_nettype wire
