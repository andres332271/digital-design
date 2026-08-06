// tb_bcd_counter.v
`timescale 1ns/1ps

module tb_bcd_counter;

  logic       clk;
  logic       rst;          // SINCRONO, activo ALTO
  logic       en;
  logic [3:0] cnt;
  logic       tc;

  integer     pulsos_tc;    // acumulador para el barrido
  integer     i;

  bcd_counter DUT (
    .clk (clk),
    .rst (rst),
    .en  (en),
    .cnt (cnt),
    .tc  (tc)
  );

  initial $timeformat(-9, 0, " ns", 10);
  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    $dumpfile("tb_bcd_counter.vcd");
    $dumpvars(0, tb_bcd_counter);
  end

  integer chequeos = 0;
  integer errores  = 0;

  // Verifica las dos salidas a la vez, informando cual fallo.
  task check(input [3:0] cnt_esp, input tc_esp, input [8*40:1] nombre);
    begin
      chequeos = chequeos + 1;
      if (cnt === cnt_esp && tc === tc_esp)
        $display("PASS [t=%0t] %0s  cnt=%0d tc=%0b", $time, nombre, cnt, tc);
      else begin
        errores = errores + 1;
        $display("FAIL [t=%0t] %0s  cnt=%0d (esp %0d)  tc=%0b (esp %0b)",
                 $time, nombre, cnt, cnt_esp, tc, tc_esp);
      end
    end
  endtask

  // Para chequeos que no son de cnt/tc (el conteo de pulsos del barrido).
  task check_int(input integer obtenido, input integer esperado,
                 input [8*40:1] nombre);
    begin
      chequeos = chequeos + 1;
      if (obtenido === esperado)
        $display("PASS [t=%0t] %0s  = %0d", $time, nombre, obtenido);
      else begin
        errores = errores + 1;
        $display("FAIL [t=%0t] %0s  = %0d, esperaba %0d",
                 $time, nombre, obtenido, esperado);
      end
    end
  endtask

  initial begin
    #50000;
    $display("FAIL: timeout, la simulacion no termino");
    $finish;
  end

  initial begin

    // ---------- Estado inicial ----------
    rst = 1'b1;
    en  = 1'b0;
    @(negedge clk);
    @(posedge clk); 
    #1;        

    // ---------- V1: reset inicial ----------
    @(negedge clk);
    en = 1'b1;
    rst = 1'b1;
    @(posedge clk); 
    #1;
    check(4'd0, 1'b0, "V1 reset domina sobre en");

    // ---------- V2: primer incremento ----------
    @(negedge clk);
    en = 1'b1;
    rst = 1'b0;
    @(posedge clk); 
    #1;
    check(4'd1, 1'b0, "V2 primer incremento");


    // ---------- V3: segundo incremento ----------
    @(negedge clk);
    en = 1'b1;
    rst = 1'b0;
    @(posedge clk); 
    #1;
    check(4'd2, 1'b0, "V3 segundo incremento");

    // ---------- V4: reset sincrono NO actua entre flancos ----------
    @(posedge clk); 
    #1;        // quedamos a mitad de ciclo
    rst = 1'b1;                // levantamos el reset ENTRE flancos
    #1;
    check(4'd3, 1'b0, "V4 reset sincrono no actua entre flancos");


    // ---------- V5: reset sincrono SI actua en el flanco ----------
    @(posedge clk); 
    #1;
    check(4'd0, 1'b0, "V5 reset sincrono actua en el flanco");
    rst = 1'b0;


    // ---------- Avance: llegar a cnt=9 ----------
    @(negedge clk);
    en = 1'b1;
    repeat (9) @(posedge clk);
    #1;


    // ---------- V6: cnt=9, tc=1 ----------
    check(4'd9,1'b1, "V6: cnt=9, tc=1");


    // ---------- V7: rollover, cnt vuelve a 0 y tc baja ----------
    @(negedge clk);
    en = 1'b1;
    rst = 1'b0;
    @(posedge clk); 
    #1;
    check(4'd0, 1'b0, "V7 rollover, cnt vuelve a 0 y tc baja");


    // ---------- V8: primer incremento tras el rollover ----------
    @(negedge clk);
    en = 1'b1;
    rst = 1'b0;
    @(posedge clk); 
    #1;
    check(4'd1, 1'b0, "V8 primer incremento tras el rollover");


    // ---------- V9: hold con en=0 durante varios ciclos ----------
    repeat (3) begin
    @(negedge clk);
    en = 1'b0;
    @(posedge clk); 
    #1;
    check(4'd1, 1'b0, "V9: hold con en=0 durante varios ciclos");
    end


    // ---------- Avance: volver a llevar cnt hasta 9 ----------
    @(negedge clk);
    en = 1'b1;
    repeat (8) @(posedge clk);
    #1;
    check(4'd9, 1'b1, "cnt=9 con en=1, tc alto");

    // ---------- V10: cnt=9 con en=0, tc debe bajar ----------
    en = 1'b0;
    #1;
    check(4'd9,1'b0,"V10: cnt=9 con en=0, tc debe bajar");

    // ---------- V11: barrido de 100 ciclos ----------
    @(negedge clk);
    rst = 1'b1;  
    en = 1'b0;
    @(posedge clk); 
    #1;
    @(negedge clk);
    rst = 1'b0;
    en = 1'b1;
    pulsos_tc = 0;
    for (i = 0; i < 100; i = i + 1) begin
      @(posedge clk); 
      #1;
      if (tc === 1'b1) pulsos_tc = pulsos_tc + 1;
    end
    check_int(pulsos_tc, 10, "V11 pulsos de tc en 100 ciclos");


    // ---------- Resumen ----------
    @(negedge clk);
    $display("");
    $display("Total: %0d   PASS: %0d   FAIL: %0d",
             chequeos, chequeos - errores, errores);
    if (errores == 0) begin
      $display("RESULTADO: PASS");
      $finish;
    end else begin
      $display("RESULTADO: FAIL");
      $fatal(1);
    end
  end

endmodule