// CORDIC circular en modo rotacion, folded: sen(theta) y cos(theta).
// theta, x_f e y_f usan S(16,14), con theta expresado en radianes.
module cordic (
    input  logic               clk,
    input  logic               rst,
    input  logic               start,
    input  logic signed [15:0] theta,
    output logic signed [15:0] x_f,       // cos(theta)
    output logic signed [15:0] y_f,       // sen(theta)
    output logic signed [15:0] theta_fin, // residual, cercano a cero
    output logic               busy,
    output logic               done
);
    localparam int N_ITER = 14;
    // round(0.607252935 * 2^14): compensacion de la ganancia CORDIC.
    localparam logic signed [15:0] K_INV = 16'sd9949;
    logic signed [15:0] x_reg, y_reg, z_reg;
    logic [3:0] iter;
    logic signed [15:0] atan_i;
    logic signed [15:0] x_next, y_next, z_next;
    logic load, iter_en, result_en;
    logic iter_last;

    cordic_atan_rom atan_rom (.addr(iter), .angle(atan_i));
    cordic_fsm control (
        .clk, .rst, .start, .iter_last,
        .load, .iter_en, .result_en, .busy, .done
    );
    assign iter_last = (iter == N_ITER - 1);

    // Las tres salidas se forman desde los registros viejos de la iteracion.
    always_comb begin
        if (z_reg >= 0) begin
            x_next = x_reg - (y_reg >>> iter);
            y_next = y_reg + (x_reg >>> iter);
            z_next = z_reg - atan_i;
        end else begin
            x_next = x_reg + (y_reg >>> iter);
            y_next = y_reg - (x_reg >>> iter);
            z_next = z_reg + atan_i;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            iter      <= '0;
            x_reg     <= '0;
            y_reg     <= '0;
            z_reg     <= '0;
            x_f       <= '0;
            y_f       <= '0;
            theta_fin <= '0;
        end else if (load) begin
            // Se cargan UNA VEZ por operacion. theta es la entrada.
            x_reg <= K_INV;
            y_reg <= '0;
            z_reg <= theta;
            iter  <= '0;
        end else if (iter_en) begin
            x_reg <= x_next;
            y_reg <= y_next;
            z_reg <= z_next;
            if (result_en) begin
                x_f       <= x_next;
                y_f       <= y_next;
                theta_fin <= z_next;
            end else begin
                iter <= iter + 1'b1;
            end
        end
    end
endmodule
