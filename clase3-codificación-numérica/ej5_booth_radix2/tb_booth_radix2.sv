`timescale 1ns/1ps
`default_nettype none

module tb_booth_radix2;

    localparam int N      = 4;
    localparam int PERIODO = 10;

    logic                   clk;
    logic                   rst_n;
    logic                   start;
    logic signed [N-1:0]    a, b;
    logic signed [2*N-1:0]  product;
    logic                   done, busy;

    int errores  = 0;
    int probados = 0;


    initial clk = 1'b0;
    always #(PERIODO/2) clk = ~clk;


    booth_radix2 #(.N(N)) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (start),
        .multiplicando (a),
        .multiplicador (b),
        .product       (product),
        .done          (done),
        .busy          (busy)
    );


    logic traza = 1'b0;

    always @(posedge clk) begin
        if (traza && dut.busy) begin
            $display("    ciclo %0d | par (%b,%b) -> %s | A=%b Q=%b Q_1=%b",
                     dut.ciclo, dut.q_reg[0], dut.q_1,
                     (dut.par == 2'b10) ? "restar " :
                     (dut.par == 2'b01) ? "sumar  " : "ninguna",
                     dut.a_reg, dut.q_reg, dut.q_1);
        end
    end


    task automatic multiplicar(
        input  int op_a,
        input  int op_b,
        output int resultado
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

            @(negedge clk);
        end
    endtask


    task automatic verificar(input int op_a, input int op_b);
        int obtenido;
        int esperado;
        begin
            multiplicar(op_a, op_b, obtenido);
            esperado = op_a * op_b;
            probados++;

            if (obtenido !== esperado) begin
                $display("  ERROR: %0d * %0d  esperado=%0d  obtenido=%0d",
                         op_a, op_b, esperado, obtenido);
                errores++;
            end
        end
    endtask


    int res;


    initial begin
        $dumpfile("tb_booth_radix2.vcd");
        $dumpvars(0, tb_booth_radix2);

        $display("==========================================================");
        $display(" Ejercicio 5 - Multiplicador de Booth radix-2 (N = %0d)", N);
        $display("==========================================================");
        $display("");

        // Reset
        rst_n = 1'b0;
        start = 1'b0;
        a     = '0;
        b     = '0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);


        $display("--- Caso del enunciado: A = +6, B = -5 ---");
        $display("  A = %0d = %b   (multiplicando)",  4'sd6, 4'sd6);
        $display("  B = %0d = %b   (multiplicador)", -4'sd5, -4'sd5);
        $display("  traza del algoritmo:");

        traza = 1'b1;
        multiplicar(6, -5, res);
        traza = 1'b0;

        $display("  producto = %0d  (%b)", res, product);

        if (res !== -30) begin
            $display("  ERROR: se esperaba -30");
            errores++;
        end else begin
            $display("  OK: coincide con A*B = -30");
        end
        $display("");


        $display("--- Casos limite del rango [%0d, %0d] ---",
                 -(2**(N-1)), 2**(N-1)-1);

        // El valor mas negativo como MULTIPLICANDO exige el acumulador
        // extendido: -(-8) no es representable en N bits.
        multiplicar(-(2**(N-1)), -(2**(N-1)), res);
        $display("  %0d * %0d = %0d   (esperado %0d)",
                 -(2**(N-1)), -(2**(N-1)), res, (2**(N-1))*(2**(N-1)));

        multiplicar(-(2**(N-1)), 2**(N-1)-1, res);
        $display("  %0d * %0d = %0d   (esperado %0d)",
                 -(2**(N-1)), 2**(N-1)-1, res, -(2**(N-1))*(2**(N-1)-1));

        multiplicar(2**(N-1)-1, 2**(N-1)-1, res);
        $display("  %0d * %0d = %0d   (esperado %0d)",
                 2**(N-1)-1, 2**(N-1)-1, res, (2**(N-1)-1)*(2**(N-1)-1));
        $display("");


        $display("--- Barrido exhaustivo: %0d pares ---", (2**N)*(2**N));

        for (int i = -(2**(N-1)); i < 2**(N-1); i++) begin
            for (int j = -(2**(N-1)); j < 2**(N-1); j++) begin
                verificar(i, j);
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


    initial begin
        #(PERIODO * 100000);
        $display(" ERROR: watchdog - la simulacion no termino a tiempo");
        $finish;
    end

endmodule

`default_nettype wire