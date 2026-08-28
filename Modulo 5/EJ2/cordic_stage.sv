// Una micro-rotacion CORDIC registrada para el pipeline.
// SHIFT es constante por instancia; por eso el shift y atan(2^-SHIFT)
// quedan fijos en hardware.
module cordic_stage #(
    parameter integer SHIFT = 0
) (
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     valid_in,
    input  logic signed [15:0]       x_in,
    input  logic signed [15:0]       y_in,
    input  logic signed [15:0]       z_in,
    output logic                     valid_out,
    output logic signed [15:0]       x_out,
    output logic signed [15:0]       y_out,
    output logic signed [15:0]       z_out
);
    logic signed [15:0] x_calc, y_calc, z_calc;

    function automatic logic signed [15:0] atan_value(input integer index);
        case (index)
            0:       atan_value = 16'sd12868;
            1:       atan_value = 16'sd7596;
            2:       atan_value = 16'sd4014;
            3:       atan_value = 16'sd2037;
            4:       atan_value = 16'sd1023;
            5:       atan_value = 16'sd512;
            6:       atan_value = 16'sd256;
            7:       atan_value = 16'sd128;
            8:       atan_value = 16'sd64;
            9:       atan_value = 16'sd32;
            10:      atan_value = 16'sd16;
            11:      atan_value = 16'sd8;
            12:      atan_value = 16'sd4;
            13:      atan_value = 16'sd2;
            default: atan_value = '0;
        endcase
    endfunction

    localparam logic signed [15:0] ATAN_I = atan_value(SHIFT);

    // Calcula una micro-rotacion. x_calc e y_calc usan x_in e y_in viejos.
    always_comb begin
        if (z_in >= 0) begin
            x_calc = x_in - (y_in >>> SHIFT);
            y_calc = y_in + (x_in >>> SHIFT);
            z_calc = z_in - ATAN_I;
        end else begin
            x_calc = x_in + (y_in >>> SHIFT);
            y_calc = y_in - (x_in >>> SHIFT);
            z_calc = z_in + ATAN_I;
        end
    end

    // El registro marca el limite entre etapas del pipeline.
    always_ff @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            x_out     <= '0;
            y_out     <= '0;
            z_out     <= '0;
        end else begin
            valid_out <= valid_in;
            x_out     <= x_calc;
            y_out     <= y_calc;
            z_out     <= z_calc;
        end
    end
endmodule
