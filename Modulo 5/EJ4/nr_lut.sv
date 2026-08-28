`timescale 1ns/1ps

module nr_lut (
    input  logic [2:0]  index,
    output logic [15:0] y0
);

  // Semillas 1/x en U(16,15), calculadas en el punto medio
  // de cada uno de los 8 subintervalos de [0.5, 1.0).
  always_comb begin
    case (index)
      3'd0: y0 = 16'hF0F1;
      3'd1: y0 = 16'hD794;
      3'd2: y0 = 16'hC30C;
      3'd3: y0 = 16'hB216;
      3'd4: y0 = 16'hA3D7;
      3'd5: y0 = 16'h97B4;
      3'd6: y0 = 16'h8D3E;
      3'd7: y0 = 16'h8421;
      default: y0 = 16'h8000;
    endcase
  end

endmodule
