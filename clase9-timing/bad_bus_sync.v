// Ejemplo incorrecto para comparar con enable_sync.
// Sincronizar cada bit por separado no garantiza una palabra coherente.
// La simulacion RTL normal no reproduce por si sola skew ni metaestabilidad.
module bad_bus_sync #(
    parameter WIDTH = 8
) (
    input  wire             clkB,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] data_async,
    output reg  [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] etapa1;

    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n) begin
            etapa1   <= {WIDTH{1'b0}};
            data_out <= {WIDTH{1'b0}};
        end else begin
            etapa1   <= data_async;
            data_out <= etapa1;
        end
    end
endmodule
