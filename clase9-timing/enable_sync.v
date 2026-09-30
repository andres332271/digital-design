`timescale 1ns/1ps

// Ejercicio 2: sincronizacion de valid con bus de datos estable.
// Los dos clocks son independientes: clkA pertenece al emisor y clkB al receptor.

module enable_sync #(
    parameter WIDTH = 8
) (
    input  wire             clkA,
    input  wire             clkB,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] data_in,
    input  wire             valid_in,
    output reg  [WIDTH-1:0] data_out,
    output reg              data_valid
);

    reg [WIDTH-1:0] data_hold;
    reg vs1;
    reg vs2;
    reg vs2_anterior;

    // Dominio clkA: guardar el bus mientras se anuncia la transferencia.
    // El emisor debe mantener data_in estable durante valid_in y no comenzar
    // otra transferencia hasta que el receptor haya tenido tiempo de verla.
    always @(posedge clkA or negedge rst_n) begin
        if (!rst_n) begin
            data_hold <= {WIDTH{1'b0}};
        end else if (valid_in)
            data_hold <= data_in;
    end

    // Dominio clkB: sincronizar valid_in y recibir el dato.
    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n) begin
            vs1          <= 1'b0;
            vs2          <= 1'b0;
            vs2_anterior <= 1'b0;
            data_out     <= {WIDTH{1'b0}};
            data_valid   <= 1'b0;
        end else begin
            vs1          <= valid_in;
            vs2          <= vs1;
            vs2_anterior <= vs2;

            // En este flanco se leen los valores anteriores de vs2 y
            // vs2_anterior. Por eso el evento aparece una sola vez.
            data_valid <= vs2 && !vs2_anterior;
            if (vs2 && !vs2_anterior)
                data_out <= data_hold;
        end
    end

endmodule
