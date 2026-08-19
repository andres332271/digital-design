`timescale 1ns/1ps
`default_nettype none

// Self-checking, combinacional: golden model embebido ($signed(a)*$signed(b))
// comparado exhaustivamente contra booth_r2 para los 256*256 pares signados.
module tb_booth_r2;

    localparam int N = 8;

    logic signed [N-1:0]   a, b;
    logic signed [2*N-1:0] product;

    int errores  = 0;
    int probados = 0;

    booth_r2 #(.N(N)) dut (
        .a       (a),
        .b       (b),
        .product (product)
    );

    initial begin
        $dumpfile("tb_booth_r2.vcd");
        $dumpvars(1, tb_booth_r2);  // sin recursion: 65536 pasos harian un VCD enorme

        $display("==========================================================");
        $display(" Ejercicio 6 - Booth radix-2 signado combinacional (N=%0d)", N);
        $display("==========================================================");
        $display(" PPs generados por operacion: %0d", N);
        $display(" Barrido exhaustivo: %0d pares", (2**N)*(2**N));
        $display("");

        for (int i = -(2**(N-1)); i < 2**(N-1); i++) begin
            for (int j = -(2**(N-1)); j < 2**(N-1); j++) begin
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
