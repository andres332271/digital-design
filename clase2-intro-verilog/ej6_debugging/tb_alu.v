`timescale 1ns / 1ps

module tb_alu;
  reg clk;
  reg rst_n;
  wire [7:0] a, b, y;
  wire [1:0] op;


  // Clock 100 MHz
  initial clk = 0;
  always #5 clk = ~clk;

  test_alu signals (
      .clk(clk),
      .rst_n(rst_n),
      .a(a),
      .b(b),
      .op(op)
  );

  alu_bad alu1 (
      .a (a),
      .b (b),
      .op(op),
      .y (y)
  );
  initial begin
    $dumpfile("tb_alu.vcd");
    $dumpvars(0, tb_alu);

    rst_n = 0;
    #12 rst_n = 1;  // Suelto reset entre flancos

    repeat (8) @(posedge clk);

    $finish;
  end
endmodule
