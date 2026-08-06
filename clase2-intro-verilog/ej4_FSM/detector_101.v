module detector_101 (
    input  wire clk,
    input  wire rst_n,  // reset asincrono activo en bajo
    input  wire x,
    output reg  y
);

  localparam [1:0] S0 = 2'b00, S1 = 2'b01, S10 = 2'b10, S101 = 2'b11;

  reg [1:0] state, next_state;

  // Registro de estado
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= S0;
    else state <= next_state;
  end

  // Logica de proximo estado
  always @(*) begin
    case (state)
      S0:      next_state = x ? S1 : S0;
      S1:      next_state = x ? S1 : S10;
      S10:     next_state = x ? S101 : S0;
      S101:    next_state = x ? S1 : S10;  // overlap: S101 se comporta como S1
      default: next_state = S0;
    endcase
  end

  // Logica de salida (Moore: y = f(estado), no f(x))
  always @(*) begin
    y = (state == S101);
  end

endmodule
