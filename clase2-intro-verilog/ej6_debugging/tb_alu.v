`timescale 1ns / 1ps

module tb_alu;
  parameter integer CLK_PERIOD = 10;
  parameter integer REG_WIDTH = 8;
  parameter integer OP_WIDTH = 2;

  parameter integer signed A_VALUE = 15;
  parameter integer signed B_VALUE = 4;
  parameter string CSV_FILENAME = "tb_alu_results.csv";

  integer i, j;
  integer csv_file;

  reg signed [REG_WIDTH-1:0] a, b;
  reg [OP_WIDTH-1:0] op;
  reg [OP_WIDTH-1:0] states[1<<OP_WIDTH];
  wire signed [REG_WIDTH-1:0] y_alu_bad, y_alu_fix1, y_alu_fix2;

  // Modulos instanciados
  alu_bad alu_bad (
      .a (a),
      .b (b),
      .op(op),
      .y (y_alu_bad)
  );

  alu_fix1 alu_fix1 (
      .a (a),
      .b (b),
      .op(op),
      .y (y_alu_fix1)
  );

  alu_fix2 alu_fix2 (
      .a (a),
      .b (b),
      .op(op),
      .y (y_alu_fix2)
  );

  // Defino tarea simple, combina dos comandos en 1.
  task automatic apply_op(reg [OP_WIDTH-1:0] state);
    begin
      op = state;
      #CLK_PERIOD;
    end
  endtask

  // Inicia el TB
  initial begin
    $dumpfile("tb_alu.vcd");
    $dumpvars(0, op, y_alu_bad, y_alu_fix1, y_alu_fix2);

    // Loegea a un archivo .csv
    csv_file = $fopen(CSV_FILENAME, "w");
    if (csv_file == 0) begin
      $display("ERROR: no se pudo abrir el archivo CSV");
      $finish;
    end
    $fwrite(csv_file, "time, op_from, op_to, y_bad, y_fix1, y_fix2\n");

    // Asigna valores iniciales
    a = A_VALUE;
    b = B_VALUE;

    for (i = 0; i < (1 << OP_WIDTH); i++) begin
      states[i] = i;
    end

    // Encabezado del .csv
    $display("t, op, alu_bad, alu_fix1, alu_fix2");

    // Bucle principal, calcula las transiciones hacia op[i] y loguea
    for (i = 0; i < (1 << OP_WIDTH); i++) begin
      for (j = 0; j < (1 << OP_WIDTH); j++) begin
        if (i != j) begin
          apply_op(states[j]);
          apply_op(states[i]);

          $fwrite(csv_file, "%0t,%b,%b,%0d,%0d,%0d\n", $time, states[j], states[i], y_alu_bad,
                  y_alu_fix1, y_alu_fix2);
        end
      end
    end
    $fclose(csv_file);
    $display("Barrido completo, resultados en %s", CSV_FILENAME);
    $finish;
  end
endmodule
