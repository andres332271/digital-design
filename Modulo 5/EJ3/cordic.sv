// CORDIC circular folded en modo vectoring.
// x_in/y_in: S(16,15). r: S(16,15). phi: S(18,14), en radianes.
// phi usa 18 bits porque S(16,14) no puede representar +pi ni -pi.
module cordic_vectoring (
    input  logic               clk,
    input  logic               rst,
    input  logic               start,
    input  logic signed [15:0] x_in,
    input  logic signed [15:0] y_in,
    output logic signed [15:0] r,
    output logic signed [17:0] phi,
    output logic signed [17:0] y_residual,
    output logic               busy,
    output logic               done
);
    localparam int N_ITER = 16;
    // K^-1 = 0.607252935 en S(16,14). Se usa al final para obtener R real.
    localparam logic signed [15:0] K_INV_Q14 = 16'sd9949;
    localparam logic signed [17:0] PI_Q14 = 18'sd51472;

    // Dos guard bits: despues de vectorizar, x puede valer K * R.
    // x/y conservan 15 bits fraccionarios; z/phi usan 14 bits fraccionarios.
    logic signed [17:0] x_reg, y_reg, x_next, y_next;
    logic signed [17:0] z_reg, z_next;
    logic [3:0] iter;
    logic signed [15:0] atan_i;
    logic signed [17:0] atan_ext;
    logic load, iter_en, result_en, iter_last;
    logic signed [33:0] r_scaled;

    cordic_atan_rom atan_rom (.addr(iter), .angle(atan_i));
    cordic_fsm control (
        .clk, .rst, .start, .iter_last,
        .load, .iter_en, .result_en, .busy, .done
    );

    assign iter_last = (iter == N_ITER - 1);
    assign atan_ext = {{2{atan_i[15]}}, atan_i};

    function automatic logic signed [15:0] saturate_s16(
        input logic signed [33:0] value
    );
        if (value > 34'sd32767)
            saturate_s16 = 16'sh7fff;
        else if (value < -34'sd32768)
            saturate_s16 = 16'sh8000;
        else
            saturate_s16 = value[15:0];
    endfunction

    // Vectoring: la decision depende de y. Las cuentas buscan y -> 0.
    always_comb begin
        if (y_reg >= 0) begin
            x_next = x_reg + (y_reg >>> iter);
            y_next = y_reg - (x_reg >>> iter);
            z_next = z_reg + atan_ext;
        end else begin
            x_next = x_reg - (y_reg >>> iter);
            y_next = y_reg + (x_reg >>> iter);
            z_next = z_reg - atan_ext;
        end

        // x_next esta en S(18,15) y K_INV_Q14 en S(16,14).
        // El producto queda con 29 fraccionales; >>>14 lo convierte a S(*,15).
        r_scaled = (x_next * K_INV_Q14) >>> 14;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            iter       <= '0;
            x_reg      <= '0;
            y_reg      <= '0;
            z_reg      <= '0;
            r          <= '0;
            phi        <= '0;
            y_residual <= '0;
        end else if (load) begin
            iter <= '0;
            // Pre-rotacion de 180 grados para cubrir los cuadrantes II y III.
            if (x_in < 0) begin
                x_reg <= -{{2{x_in[15]}}, x_in};
                y_reg <= -{{2{y_in[15]}}, y_in};
                if (y_in >= 0) z_reg <= PI_Q14;
                else           z_reg <= -PI_Q14;
            end else begin
                x_reg <= {{2{x_in[15]}}, x_in};
                y_reg <= {{2{y_in[15]}}, y_in};
                z_reg <= '0;
            end
        end else if (iter_en) begin
            x_reg <= x_next;
            y_reg <= y_next;
            z_reg <= z_next;
            if (result_en) begin
                r          <= saturate_s16(r_scaled);
                phi        <= z_next;
                y_residual <= y_next;
            end else begin
                iter <= iter + 1'b1;
            end
        end
    end
endmodule
