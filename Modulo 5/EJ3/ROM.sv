// Tabla atan(2^-i), codificada en radianes S(16,14).
module cordic_atan_rom (
    input  logic [3:0] addr,
    output logic signed [15:0] angle
);
    always_comb begin
        case (addr)
            4'd0:  angle = 16'sd12868; // atan(1)
            4'd1:  angle = 16'sd7596;
            4'd2:  angle = 16'sd4014;
            4'd3:  angle = 16'sd2037;
            4'd4:  angle = 16'sd1023;
            4'd5:  angle = 16'sd512;
            4'd6:  angle = 16'sd256;
            4'd7:  angle = 16'sd128;
            4'd8:  angle = 16'sd64;
            4'd9:  angle = 16'sd32;
            4'd10: angle = 16'sd16;
            4'd11: angle = 16'sd8;
            4'd12: angle = 16'sd4;
            4'd13: angle = 16'sd2;
            4'd14: angle = 16'sd1;
            4'd15: angle = 16'sd0; // atan(2^-15) se cuantiza a cero en S(16,14)
            default: angle = '0;
        endcase
    end
endmodule
