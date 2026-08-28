`timescale 1ns/1ps

module tb_nr;
  localparam real MAX_FINAL_ABS_ERROR = 0.0002;

  logic clk;
  logic rst_n;
  logic start;
  logic [15:0] a;

  logic [2:0]  lut_index;
  logic [15:0] seed_y0;

  logic [15:0] result_n1;
  logic [15:0] result_n2;
  logic [15:0] result_n3;
  logic [15:0] result_n4;
  logic done_n1, done_n2, done_n3, done_n4;

  real max_abs_n0, max_abs_n1, max_abs_n2, max_abs_n3, max_abs_n4;
  real max_rel_n0, max_rel_n1, max_rel_n2, max_rel_n3, max_rel_n4;
  integer errors;
  integer csv_file;
  integer i;

  always #5 clk = ~clk;

  assign lut_index = a[14:12];

  // N=0 representa el resultado de usar solamente la semilla de la LUT.
  nr_lut u_seed_lut (
      .index(lut_index),
      .y0   (seed_y0)
  );

  nr #(.N_ITER(1)) dut_n1 (
      .clk(clk), .rst_n(rst_n), .start(start), .a(a),
      .result(result_n1), .done(done_n1)
  );

  nr #(.N_ITER(2)) dut_n2 (
      .clk(clk), .rst_n(rst_n), .start(start), .a(a),
      .result(result_n2), .done(done_n2)
  );

  nr #(.N_ITER(3)) dut_n3 (
      .clk(clk), .rst_n(rst_n), .start(start), .a(a),
      .result(result_n3), .done(done_n3)
  );

  nr #(.N_ITER(4)) dut_n4 (
      .clk(clk), .rst_n(rst_n), .start(start), .a(a),
      .result(result_n4), .done(done_n4)
  );

  function automatic real abs_real(input real value);
    if (value < 0.0)
      abs_real = -value;
    else
      abs_real = value;
  endfunction

  function automatic real q15_to_real(input logic [15:0] value);
    q15_to_real = $itor(value) / 32768.0;
  endfunction

  function automatic real q16_to_real(input logic [15:0] value);
    q16_to_real = $itor(value) / 65536.0;
  endfunction

  task automatic update_maximums(
      input real abs0, input real abs1, input real abs2,
      input real abs3, input real abs4,
      input real rel0, input real rel1, input real rel2,
      input real rel3, input real rel4
  );
    begin
      if (abs0 > max_abs_n0) max_abs_n0 = abs0;
      if (abs1 > max_abs_n1) max_abs_n1 = abs1;
      if (abs2 > max_abs_n2) max_abs_n2 = abs2;
      if (abs3 > max_abs_n3) max_abs_n3 = abs3;
      if (abs4 > max_abs_n4) max_abs_n4 = abs4;

      if (rel0 > max_rel_n0) max_rel_n0 = rel0;
      if (rel1 > max_rel_n1) max_rel_n1 = rel1;
      if (rel2 > max_rel_n2) max_rel_n2 = rel2;
      if (rel3 > max_rel_n3) max_rel_n3 = rel3;
      if (rel4 > max_rel_n4) max_rel_n4 = rel4;
    end
  endtask

  task automatic write_csv_row(
      input string case_name,
      input logic [15:0] a_code,
      input integer n_iter,
      input real obtained,
      input real expected,
      input real abs_error,
      input real rel_error
  );
    begin
      $fdisplay(csv_file, "%s,0x%04h,%0.9f,%0d,%0.9f,%0.9f,%0.9f,%0.9f",
                case_name, a_code, q16_to_real(a_code), n_iter, obtained,
                expected, abs_error, rel_error);
    end
  endtask

  task automatic run_case(
      input logic [15:0] a_code,
      input string case_name
  );
    logic [15:0] result_n0_saved;
    logic [15:0] result_n1_saved;
    logic [15:0] result_n2_saved;
    logic [15:0] result_n3_saved;
    logic [15:0] result_n4_saved;
    real a_real;
    real expected;
    real obtained0, obtained1, obtained2, obtained3, obtained4;
    real abs0, abs1, abs2, abs3, abs4;
    real rel0, rel1, rel2, rel3, rel4;
    begin
      // No se inicia una operacion nueva hasta que todas las FSM vuelvan a IDLE.
      wait (!(done_n1 || done_n2 || done_n3 || done_n4));
      @(negedge clk);
      a = a_code;
      #1;
      result_n0_saved = seed_y0;
      start = 1'b1;

      @(negedge clk);
      start = 1'b0;

      wait (done_n1);
      #1 result_n1_saved = result_n1;
      wait (done_n2);
      #1 result_n2_saved = result_n2;
      wait (done_n3);
      #1 result_n3_saved = result_n3;
      wait (done_n4);
      #1 result_n4_saved = result_n4;

      a_real  = q16_to_real(a_code);
      expected = 1.0 / a_real;
      obtained0 = q15_to_real(result_n0_saved);
      obtained1 = q15_to_real(result_n1_saved);
      obtained2 = q15_to_real(result_n2_saved);
      obtained3 = q15_to_real(result_n3_saved);
      obtained4 = q15_to_real(result_n4_saved);

      abs0 = abs_real(obtained0 - expected);
      abs1 = abs_real(obtained1 - expected);
      abs2 = abs_real(obtained2 - expected);
      abs3 = abs_real(obtained3 - expected);
      abs4 = abs_real(obtained4 - expected);
      rel0 = abs0 / expected;
      rel1 = abs1 / expected;
      rel2 = abs2 / expected;
      rel3 = abs3 / expected;
      rel4 = abs4 / expected;

      update_maximums(abs0, abs1, abs2, abs3, abs4,
                      rel0, rel1, rel2, rel3, rel4);

      write_csv_row(case_name, a_code, 0, obtained0, expected, abs0, rel0);
      write_csv_row(case_name, a_code, 1, obtained1, expected, abs1, rel1);
      write_csv_row(case_name, a_code, 2, obtained2, expected, abs2, rel2);
      write_csv_row(case_name, a_code, 3, obtained3, expected, abs3, rel3);
      write_csv_row(case_name, a_code, 4, obtained4, expected, abs4, rel4);

      $display("%-14s a=%0.6f | error abs N=0:%0.7f N=1:%0.7f N=2:%0.7f N=3:%0.7f N=4:%0.7f",
               case_name, a_real, abs0, abs1, abs2, abs3, abs4);

      if (abs4 > MAX_FINAL_ABS_ERROR) begin
        errors = errors + 1;
        $display("ERROR: %s supera la tolerancia final: %0.9f", case_name, abs4);
      end

      // Deja que la instancia N=4 salga de DONE antes del caso siguiente.
      @(negedge clk);
    end
  endtask

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;
    a = '0;
    errors = 0;
    max_abs_n0 = 0.0;
    max_abs_n1 = 0.0;
    max_abs_n2 = 0.0;
    max_abs_n3 = 0.0;
    max_abs_n4 = 0.0;
    max_rel_n0 = 0.0;
    max_rel_n1 = 0.0;
    max_rel_n2 = 0.0;
    max_rel_n3 = 0.0;
    max_rel_n4 = 0.0;

    csv_file = $fopen("error_vs_n.csv", "w");
    if (csv_file == 0) begin
      $fatal(1, "No se pudo crear error_vs_n.csv");
    end
    $fdisplay(csv_file,
              "caso,a_codigo,a_real,N_ITER,resultado,esperado,error_absoluto,error_relativo");

    $dumpfile("sim_nr.vcd");
    $dumpvars(0, tb_nr);

    repeat (2) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;

    // Limites y puntos medios de los ocho intervalos de la LUT.
    for (i = 0; i < 8; i = i + 1) begin
      run_case(16'h8000 + (i << 12), $sformatf("limite_%0d", i));
      run_case(16'h8800 + (i << 12), $sformatf("medio_%0d", i));
    end

    // Casos adicionales y el mayor valor posible de U(16,16).
    run_case(16'h999A, "a_0.6");
    run_case(16'hB333, "a_0.7");
    run_case(16'hCCCD, "a_0.8");
    run_case(16'hE666, "a_0.9");
    run_case(16'hFFFF, "maximo");

    $display("\nResumen: error maximo observado versus N");
    $display(" N | error absoluto maximo | error relativo maximo");
    $display("---+-----------------------+----------------------");
    $display(" 0 | %0.9f           | %0.9f", max_abs_n0, max_rel_n0);
    $display(" 1 | %0.9f           | %0.9f", max_abs_n1, max_rel_n1);
    $display(" 2 | %0.9f           | %0.9f", max_abs_n2, max_rel_n2);
    $display(" 3 | %0.9f           | %0.9f", max_abs_n3, max_rel_n3);
    $display(" 4 | %0.9f           | %0.9f", max_abs_n4, max_rel_n4);

    $fclose(csv_file);

    if (errors == 0)
      $display("PASS: todos los casos cumplen error absoluto <= %0.7f para N=4.",
               MAX_FINAL_ABS_ERROR);
    else
      $fatal(1, "FAIL: %0d casos fuera de tolerancia", errors);

    $finish;
  end

endmodule
