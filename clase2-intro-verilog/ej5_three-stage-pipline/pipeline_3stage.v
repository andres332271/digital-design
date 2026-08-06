module pipeline_3stage (
    input  wire        clk,
    input  wire        rst_n,      // reset asíncrono activo en bajo (ajustar si tu cátedra pide sync)

    // Interfaz de entrada (AXI-Stream esclavo)
    input  wire signed [7:0]  x_in,
    input  wire                valid_in,
    output wire                ready_out,

    // Interfaz de salida (AXI-Stream maestro)
    output reg  signed [15:0] y_out,
    output reg                 valid_out,
    input  wire                ready_in
);

    localparam signed [7:0] A = 8'sd5;
    localparam signed [7:0] B = 8'sd3;

    // Enable único: si el consumidor no está listo, nadie avanza
    wire enable = ready_in;
    assign ready_out = ready_in;

    // Registros de etapa 1 (suma) y etapa 2 (producto)
    reg signed [15:0] d1, v1_data; // d1 = x+A
    reg                v1;
    reg signed [15:0] d2;          // d2 = d1*B
    reg                v2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v1 <= 1'b0; d1 <= 16'sd0;
            v2 <= 1'b0; d2 <= 16'sd0;
            valid_out <= 1'b0; y_out <= 16'sd0;
        end else if (enable) begin
            // Etapa 1: suma
            v1 <= valid_in;
            d1 <= $signed(x_in) + A;

            // Etapa 2: producto
            v2 <= v1;
            d2 <= d1 * B;

            // Etapa 3: shift aritmético
            valid_out <= v2;
            y_out     <= d2 >>> 4;
        end
        // si enable=0, todo mantiene su valor (freeze)
    end

endmodule
