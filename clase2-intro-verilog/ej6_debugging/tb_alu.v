`timescale 1ns / 1ps

module tb_alu;
  reg [7:0] a, b;
  reg  [1:0] op;
  wire [7:0] y;

  alu_bad alu1 (
      .a (a),
      .b (b),
      .op(op),
      .y (y)
  );

  initial begin
    $dumpfile("tb_alu.vcd");
    $dumpvars(0, tb_alu);

    a  = 8'd15;
    b  = 8'd4;

    // 00 -> 01
    op = 2'b00;
    #10;
    op = 2'b01;
    #10;

    // 00 -> 10
    op = 2'b00;
    #10;
    op = 2'b10;
    #10;

    // 00 -> 11
    op = 2'b00;
    #10;
    op = 2'b11;
    #10;

    // 01 -> 00
    op = 2'b01;
    #10;
    op = 2'b00;
    #10;

    // 01 -> 10
    op = 2'b01;
    #10;
    op = 2'b10;
    #10;

    // 01 -> 11
    op = 2'b01;
    #10;
    op = 2'b11;
    #10;

    // 10 -> 00
    op = 2'b10;
    #10;
    op = 2'b00;
    #10;

    // 10 -> 01
    op = 2'b10;
    #10;
    op = 2'b01;
    #10;

    // 10 -> 11
    op = 2'b10;
    #10;
    op = 2'b11;
    #10;

    // 11 -> 00
    op = 2'b11;
    #10;
    op = 2'b00;
    #10;

    // 11 -> 01
    op = 2'b11;
    #10;
    op = 2'b01;
    #10;

    // 11 -> 10
    op = 2'b11;
    #10;
    op = 2'b10;
    #10;

    $finish;
  end
endmodule
