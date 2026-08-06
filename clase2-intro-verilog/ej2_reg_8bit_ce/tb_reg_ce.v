`timescale 1ns/1ps

module tb_reg_ce;
  localparam WIDTH = 8;
  logic             clk;
  logic             rst_n;
  logic             ce;
  logic [WIDTH-1:0] d, q;

  logic [WIDTH-1:0]   esperado;

  integer i;

  reg_ce #(.WIDTH(WIDTH)) DUT (
    .clk   (clk),
    .rst_n (rst_n),
    .d     (d),
    .ce     (ce),
    .q     (q)
  );

  initial $timeformat(-9, 0, " ns", 10);
  initial clk = 1'b0;
  always #5 clk = ~clk;      // semiperiodo 5 ns -> periodo 10 ns -> 100 MHz


  initial begin
    $dumpfile("tb_reg_ce.vcd");
    $dumpvars(0, tb_reg_ce);
  end

  integer chequeos = 0;
  integer errores  = 0;

  task check(input [WIDTH-1:0] valor_esperado, input [8*40:1] nombre);
    begin
      chequeos = chequeos + 1;
      if (q === valor_esperado)
        $display("PASS [t=%0t] %0s  q=%0h", $time, nombre, q);
      else begin
        errores = errores + 1;
        $display("FAIL [t=%0t] %0s  q=%0h, esperaba %0h",
                 $time, nombre, q, valor_esperado);
      end
    end
  endtask

  initial begin
    #10000;
    $display("FAIL: timeout, la simulacion no termino");
    $finish;
  end

  initial begin

    // ---------- Estado inicial ----------
    // El reset arranca ACTIVO (rst_n = 0, porque es activo bajo).
    rst_n = 1'b0;
    d     = 8'h00;
    ce    = 1'b1;


    // ---------- VECTOR 1 - Reset Inicial ----------
    #1;                                    
    check(8'h00, "V1 reset fuerza q=h00");

    // ---------- Liberar el reset ----------
    @(negedge clk);
    rst_n = 1'b1;


    // ---------- VECTOR 2 - Escritura normal ce=1 ----------
    @(negedge clk);                       
      d = 8'h10;
      ce = 1'b1;
      esperado = 8'h10;                    
    @(posedge clk);                        
    #1;                                    
    check(esperado, "Escritura normal ce=1");


    // ---------- VECTOR 3 — 2° Escritura normal ce=1 ----------
    @(negedge clk);
      d = 8'hC4;
      ce = 1'b1;
      esperado = 8'hC4;
    @(posedge clk); #1;
    check(esperado, "Segunda Escritura normal ce=1");


    // ---------- VECTOR 4, 5 y 6 — Hold con ce=0 ----------
    for (i = 0; i < 3; i = i + 1) begin
      @(negedge clk);
        d = 8'h11 + i[7:0];
        ce = 1'b0;
      @(posedge clk); #1;
      check(esperado, "V4-6 hold: d cambia, q no");
    end


    // ---------- VECTOR 7 — Re-activamos ce=1 ----------
    @(negedge clk);
        ce = 1'b1;
        d = 8'hAA;
        esperado = 8'hAA;
    @(posedge clk); #1;
    check(esperado, "V7 reactivamos ce=1");


    // ---------- VECTOR 8 — Caso borde inferior d = 8'h00 ----------
    @(negedge clk);
        d = 8'h00;
        ce = 1'b1;
        esperado = 8'h00;
    @(posedge clk); #1;
    check(esperado, "Caso borde inferior d = 8'h00");


    // ---------- VECTOR 9 — Caso borde superior d = 8'hFF ----------
    @(negedge clk);
        d = 8'hFF;
        ce = 1'b1;
        esperado = 8'hFF;
    @(posedge clk); #1;
    check(esperado, "Caso borde superior d = 8'hFF");


    // ---------- V10— Reset en caliente ----------
    @(posedge clk); #1;                    
    rst_n = 1'b0;                          
    #1;                                    
    check(8'h00, "V10 reset asincrono actua sin flanco");
    rst_n = 1'b1;                          


    // ---------- Resumen final ----------
    @(negedge clk);
    $display("");
    $display("Total: %0d   PASS: %0d   FAIL: %0d",
             chequeos, chequeos - errores, errores);
    if (errores == 0) begin
      $display("RESULTADO: PASS");
      $finish;
    end else begin
      $display("RESULTADO: FAIL");
      $fatal(1);   // codigo de salida != 0, para que set -e lo detecte
                   // (si tu version de iverilog no soporta $fatal, usar $finish)
    end
  end

endmodule