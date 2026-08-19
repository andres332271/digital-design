`timescale 1ns/1ps
`default_nettype none

// Self-checking, combinacional: golden model embebido (esperado = a*b con el
// operador '*' de SystemVerilog) comparado exhaustivamente contra array_mul
// para los 256*256 pares posibles.
module tb_array_mul;

    localparam int N = 8;

    logic [N-1:0]   a, b;
    logic [2*N-1:0] product;

    int errores  = 0;
    int probados = 0;

    array_mul #(.N(N)) dut (
        .a       (a),
        .b       (b),
        .product (product)
    );

    initial begin
        $dumpfile("tb_array_mul.vcd");
        $dumpvars(1, tb_array_mul);  // sin recursion: 65536 pasos harian un VCD enorme

        $display("==========================================================");
        $display(" Ejercicio 5 - Array multiplier combinacional (N=%0d)", N);
        $display("==========================================================");
        $display(" Barrido exhaustivo: %0d pares", (2**N)*(2**N));
        $display("");

        for (int i = 0; i < 2**N; i++) begin
            for (int j = 0; j < 2**N; j++) begin
                a = N'(i);
                b = N'(j);
                #1;

                if (product !== (2*N)'(i * j)) begin
                    $display("  ERROR: %0d * %0d  esperado=%0d  obtenido=%0d",
                              i, j, i * j, product);
                    errores++;
                end
                probados++;
            end
        end

        $display("  pares verificados: %0d", probados);
        $display("");
        $display("==========================================================");
        if (errores == 0)
            $display(" RESULTADO: OK - sin discrepancias");
        else
            $display(" RESULTADO: FALLO - %0d discrepancias", errores);
        $display("==========================================================");

        $finish;
    end

endmodule

`default_nettype wire
