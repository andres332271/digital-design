// Ejercicio 2: completar los TODO sin cambiar la interfaz del modulo.
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
    always @(posedge clkA or negedge rst_n) begin
        if (!rst_n) begin
            data_hold <= {WIDTH{1'b0}};
        end else begin
            // TODO 1: guardar data_in en data_hold cuando valid_in = 1.
        end
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
            // TODO 2: implementar vs1 <= valid_in; y vs2 <= vs1;.
            // TODO 3: recordar el valor previo de vs2 en vs2_anterior.
            // TODO 4: generar data_valid durante un solo ciclo de clkB
            //         al detectar el flanco ascendente de vs2.
            // TODO 5: en ese mismo evento, copiar data_hold a data_out.
        end
    end

endmodule
