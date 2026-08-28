// CORDIC de rotacion pipelineado: acepta un theta por ciclo.
// La salida de una entrada valida aparece 14 ciclos despues con valid_out=1.
module cordic_pipeline (
    input  logic               clk,
    input  logic               rst,
    input  logic               valid_in,
    input  logic signed [15:0] theta,
    output logic               valid_out,
    output logic signed [15:0] cos_theta,
    output logic signed [15:0] sen_theta,
    output logic signed [15:0] theta_fin
);
    localparam integer N_ITER = 14;
    localparam logic signed [15:0] K_INV = 16'sd9949; // 1/K en S(16,14)

    // Indice 0: entrada. Indice 14: salida de la ultima etapa.
    logic signed [15:0] x_pipe [0:N_ITER];
    logic signed [15:0] y_pipe [0:N_ITER];
    logic signed [15:0] z_pipe [0:N_ITER];
    logic               valid_pipe [0:N_ITER];
    logic signed [15:0] x0, y0, z0;
    logic               valid0;

    // Registro de entrada: una muestra aceptada en un flanco atraviesa las
    // 14 etapas y aparece exactamente 14 ciclos despues en valid_out.
    always_ff @(posedge clk) begin
        if (rst) begin
            x0     <= '0;
            y0     <= '0;
            z0     <= '0;
            valid0 <= 1'b0;
        end else begin
            x0     <= K_INV;
            y0     <= '0;
            z0     <= theta;
            valid0 <= valid_in;
        end
    end

    genvar i;
    generate
        for (i = 0; i < N_ITER; i = i + 1) begin : g_cordic_stages
            if (i == 0) begin : g_first_stage
                cordic_stage #(.SHIFT(i)) stage_i (
                    .clk(clk), .rst(rst), .valid_in(valid0),
                    .x_in(x0), .y_in(y0), .z_in(z0),
                    .valid_out(valid_pipe[i+1]), .x_out(x_pipe[i+1]),
                    .y_out(y_pipe[i+1]), .z_out(z_pipe[i+1])
                );
            end else begin : g_remaining_stages
                cordic_stage #(.SHIFT(i)) stage_i (
                    .clk(clk), .rst(rst), .valid_in(valid_pipe[i]),
                    .x_in(x_pipe[i]), .y_in(y_pipe[i]), .z_in(z_pipe[i]),
                    .valid_out(valid_pipe[i+1]), .x_out(x_pipe[i+1]),
                    .y_out(y_pipe[i+1]), .z_out(z_pipe[i+1])
                );
            end
        end
    endgenerate

    assign valid_out = valid_pipe[N_ITER];
    assign cos_theta = x_pipe[N_ITER];
    assign sen_theta = y_pipe[N_ITER];
    assign theta_fin = z_pipe[N_ITER];
endmodule
