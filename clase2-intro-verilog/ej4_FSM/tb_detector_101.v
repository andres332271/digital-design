`timescale 1ns/1ps

module tb_detector_101;

  localparam [1:0] S0   = 2'b00,
                    S1   = 2'b01,
                    S10  = 2'b10,
                    S101 = 2'b11;

  reg  clk, rst_n, x;
  wire y;

  integer errors, exp_detections, obt_detections, i;
  reg [1:0] model_state, model_next;

  // secuencia de prueba pedida por la consigna
  localparam integer N = 11;
  reg [N-1:0] seq = 11'b110_1011_0101;  // "11010110101", bit N-1 se envia primero

  detector_101 dut (
      .clk   (clk),
      .rst_n (rst_n),
      .x     (x),
      .y     (y)
  );

  always #5 clk = ~clk;  // clock 100MHz

  // replica la tabla de transicion del DUT para calcular el y esperado
  function automatic [1:0] golden_next;
    input [1:0] state;
    input       xin;
    begin
      case (state)
        S0:   golden_next = xin ? S1   : S0;
        S1:   golden_next = xin ? S1   : S10;
        S10:  golden_next = xin ? S101 : S0;
        S101: golden_next = xin ? S1   : S10;
        default: golden_next = S0;
      endcase
    end
  endfunction

  initial begin
    $dumpfile("tb_detector_101.vcd");
    $dumpvars(0, tb_detector_101);

    clk = 0;
    x = 0;
    errors = 0;
    exp_detections = 0;
    obt_detections = 0;
    model_state = S0;

    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
    @(negedge clk);

    for (i = N - 1; i >= 0; i = i - 1) begin
      x = seq[i];
      model_next = golden_next(model_state, x);
      @(posedge clk);
      #1;
      if (model_next == S101) exp_detections = exp_detections + 1;
      if (y == 1'b1) obt_detections = obt_detections + 1;
      if (y !== (model_next == S101)) begin
        errors = errors + 1;
        $display("[%0t] ERROR: bit=%0d x=%b y=%b esperado=%b", $time, N - i, x, y,
                  (model_next == S101));
      end
      model_state = model_next;
      @(negedge clk);
    end

    $display("----------------------------------------");
    $display("Detecciones esperadas: %0d", exp_detections);
    $display("Detecciones obtenidas: %0d", obt_detections);
    $display("Errores:               %0d", errors);
    if (errors == 0 && exp_detections == obt_detections)
      $display("RESULTADO: PASS");
    else
      $display("RESULTADO: FAIL");
    $display("----------------------------------------");
    $finish;
  end

endmodule
