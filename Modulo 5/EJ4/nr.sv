`timescale 1ns/1ps

module nr #(
    parameter int N_ITER = 4
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [15:0] a,
    output logic [15:0] result,
    output logic        done
);

  logic en, sel;

  // a llega en U(16,16). El datapath trabaja en U(16,15).
  logic [15:0] a_reg;
  logic [15:0] a_q15;
  logic [2:0]  lut_index;

  logic [15:0] y0;
  logic [15:0] y_reg;
  logic [15:0] y_next;

  // Productos U(16,15) x U(16,15) = 32 bits con 30 fraccionarios.
  logic [31:0] product_ay;
  logic [31:0] product_ye;
  logic [16:0] p_q15;
  logic [16:0] e_ext;
  logic [15:0] e_q15;
  logic [16:0] y_scaled;

  fsm #(
      .N_ITER(N_ITER)
  ) u_fsm (
      .clk  (clk),
      .rst_n(rst_n),
      .start(start),
      .en   (en),
      .sel  (sel),
      .done (done)
  );

  nr_lut u_lut (
      .index(lut_index),
      .y0   (y0)
  );

  // Conversion U(16,16) -> U(16,15) e indice de los 8 intervalos.
  assign a_q15     = a_reg >> 1;
  assign lut_index = a_reg[14:12];

  // Registros del datapath. En INIT se carga y0; en ITER, el feedback.
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      a_reg <= '0;
      y_reg <= '0;
    end else begin
      if (start) begin
        a_reg <= a;
      end

      if (en) begin
        y_reg <= sel ? y_next : y0;
      end
    end
  end

  // Una iteracion: y_next = y * (2 - a*y).
  // Cada producto se trunca al volver a U(16,15).
  assign product_ay = a_q15 * y_reg;
  assign p_q15      = product_ay[31:15];

  // 2.0 necesita 17 bits en escala Q15.
  assign e_ext = 17'h10000 - p_q15;
  assign e_q15 = e_ext[15:0];

  assign product_ye = y_reg * e_q15;
  assign y_scaled   = product_ye[31:15];

  // U(16,15) no representa 2.0: se satura al mayor valor posible.
  assign y_next = y_scaled[16] ? 16'hFFFF : y_scaled[15:0];

  assign result = y_reg;

endmodule
