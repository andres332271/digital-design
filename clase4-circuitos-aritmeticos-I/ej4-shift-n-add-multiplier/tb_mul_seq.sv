`timescale 1ns/1ps
`default_nettype none

// Self-checking: golden model embebido (esperado = a*b, unsigned) comparado
// contra mul_seq. Ademas mide ciclos de latencia por operacion via dut.busy.
module tb_mul_seq;

    localparam int N       = 8;
    localparam int PERIODO = 10;
    localparam int N_ALEATORIOS = 200;

    logic                  clk;
    logic                  rst_n;
    logic                  start;
    logic        [N-1:0]   a, b;
    logic        [2*N-1:0] product;
    logic                  done, busy;

    int errores       = 0;
    int probados      = 0;
    int ciclos_mal    = 0;
    integer seed      = 1;

    initial clk = 1'b0;
    always #(PERIODO/2) clk = ~clk;

    mul_seq #(.N(N)) dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (start),
        .a       (a),
        .b       (b),
        .product (product),
        .done    (done),
        .busy    (busy)
    );

    // Cuenta ciclos de COMPUTE de la operacion en curso (entregable:
    // conteo de ciclos por operacion).
    logic [7:0] ciclos_op;
    always_ff @(posedge clk) begin
        if (dut.load)      ciclos_op <= '0;
        else if (dut.busy) ciclos_op <= ciclos_op + 8'd1;
    end

    task automatic multiplicar(
        input  int op_a,
        input  int op_b,
        output int resultado,
        output int ciclos
    );
        begin
            @(negedge clk);
            a     = N'(op_a);
            b     = N'(op_b);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            wait (done);
            resultado = int'(product);
            ciclos    = int'(ciclos_op);

            @(negedge clk);
        end
    endtask

    task automatic verificar(input int op_a, input int op_b);
        int obtenido;
        int esperado;
        int ciclos;
        begin
            multiplicar(op_a, op_b, obtenido, ciclos);
            esperado = op_a * op_b;
            probados++;

            if (obtenido !== esperado) begin
                $display("  ERROR: %0d * %0d  esperado=%0d  obtenido=%0d",
                          op_a, op_b, esperado, obtenido);
                errores++;
            end
            if (ciclos != N) begin
                $display("  ERROR ciclos: %0d * %0d tardo %0d ciclos (esperado %0d)",
                          op_a, op_b, ciclos, N);
                ciclos_mal++;
            end
        end
    endtask

    int res, ciclos_res;

    initial begin
        $dumpfile("tb_mul_seq.vcd");
        $dumpvars(0, tb_mul_seq);

        $display("==========================================================");
        $display(" Ejercicio 4 - Multiplicador shift-and-add secuencial (N=%0d)", N);
        $display("==========================================================");
        $display("");

        rst_n = 1'b0;
        start = 1'b0;
        a     = '0;
        b     = '0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        $display("--- Casos limite [0, %0d] ---", 2**N - 1);
        multiplicar(0, 0, res, ciclos_res);
        $display("  0 * 0 = %0d  (%0d ciclos, esperado %0d)", res, ciclos_res, N);
        multiplicar(2**N-1, 2**N-1, res, ciclos_res);
        $display("  %0d * %0d = %0d  (%0d ciclos, esperado %0d)",
                  2**N-1, 2**N-1, res, ciclos_res, N);
        multiplicar(0, 2**N-1, res, ciclos_res);
        $display("  0 * %0d = %0d  (%0d ciclos, esperado %0d)", 2**N-1, res, ciclos_res, N);
        multiplicar(1, 1, res, ciclos_res);
        $display("  1 * 1 = %0d  (%0d ciclos, esperado %0d)", res, ciclos_res, N);
        $display("");

        verificar(0, 0);
        verificar(2**N-1, 2**N-1);
        verificar(0, 2**N-1);
        verificar(1, 1);
        verificar(2**N-1, 1);

        $display("--- %0d pares pseudoaleatorios (semilla fija) ---", N_ALEATORIOS);
        for (int i = 0; i < N_ALEATORIOS; i++) begin
            verificar($random(seed) & (2**N-1), $random(seed) & (2**N-1));
        end

        $display("  pares verificados: %0d", probados);
        $display("");
        $display("==========================================================");
        if (errores == 0)
            $display(" RESULTADO: OK - sin discrepancias");
        else
            $display(" RESULTADO: FALLO - %0d discrepancias", errores);

        if (ciclos_mal == 0)
            $display(" LATENCIA: OK - %0d ciclos constantes en las %0d operaciones", N, probados);
        else
            $display(" LATENCIA: FALLO - %0d operaciones con ciclos distintos de %0d", ciclos_mal, N);
        $display("==========================================================");

        $finish;
    end

    initial begin
        #(PERIODO * 100000);
        $display(" ERROR: watchdog - la simulacion no termino a tiempo");
        $finish;
    end

endmodule

`default_nettype wire
