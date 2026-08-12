`timescale 1ns/1ps
`default_nettype none

module tb_rns_multiplicacion_modular;

    import rns_pkg::*;

    logic [WBIN-1:0] x, y, z;
    logic [W1-1:0]   xr1, yr1, zr1;
    logic [W2-1:0]   xr2, yr2, zr2;
    logic [W3-1:0]   xr3, yr3, zr3;

    int errores  = 0;
    int probados = 0;


    rns_multiplicacion_modular dut (
        .x   (x),   .y   (y),   .z   (z),
        .xr1 (xr1), .xr2 (xr2), .xr3 (xr3),
        .yr1 (yr1), .yr2 (yr2), .yr3 (yr3),
        .zr1 (zr1), .zr2 (zr2), .zr3 (zr3)
    );


    task automatic verificar(input int op_x, input int op_y);
        int esperado;
        begin
            x = WBIN'(op_x);
            y = WBIN'(op_y);
            #1;

            esperado = op_x * op_y;
            probados++;

            if (z !== WBIN'(esperado)) begin
                $display("  ERROR: %0d * %0d  esperado=%0d  obtenido=%0d",
                         op_x, op_y, esperado, z);
                errores++;
            end
        end
    endtask

    //--------------------------------------------------------------------------
    int esperado_wrap;

    initial begin
        $dumpfile("tb_rns_multiplicacion_modular.vcd");
        $dumpvars(0, tb_rns_multiplicacion_modular);

        $display("==========================================================");
        $display(" Ejercicio 6 - RNS con modulos {%0d, %0d, %0d}, M = %0d",
                 M1, M2, M3, M);
        $display("==========================================================");
        $display("");


        $display("--- Caso del enunciado: X = 14, Y = 6 ---");

        x = WBIN'(14);
        y = WBIN'(6);
        #1;

        $display("  X = %0d  ->  (%0d, %0d, %0d)", x, xr1, xr2, xr3);
        $display("  Y = %0d   ->  (%0d, %0d, %0d)", y, yr1, yr2, yr3);
        $display("  producto residuo a residuo  ->  (%0d, %0d, %0d)",
                 zr1, zr2, zr3);
        $display("  recomposicion por TCR: Z = %0d", z);

        if (z !== WBIN'(84)) begin
            $display("  ERROR: se esperaba 84");
            errores++;
        end else begin
            $display("  OK: coincide con X*Y = 84");
        end
        $display("");


        $display("--- Barrido sobre el rango representable [0, %0d) ---", M);

        for (int i = 0; i < M; i++) begin
            for (int j = 0; j < M; j++) begin
                if (i * j < M) begin
                    verificar(i, j);
                end
            end
        end

        $display("  pares verificados: %0d", probados);
        $display("");


        $display("--- Comportamiento fuera del rango representable ---");

        x = WBIN'(14);
        y = WBIN'(9);
        #1;
        esperado_wrap = (14 * 9) % M;

        $display("  X = 14, Y = 9  ->  producto verdadero = %0d  (> M = %0d)",
                 14 * 9, M);
        $display("  el DUT devuelve Z = %0d, es decir %0d mod %0d = %0d",
                 z, 14 * 9, M, esperado_wrap);
        $display("  no se emite ninguna senal de desborde");

        if (z !== WBIN'(esperado_wrap)) begin
            $display("  ERROR: la reduccion no coincide con lo previsto");
            errores++;
        end
        $display("");

        //----------------------------------------------------------------------
        $display("==========================================================");
        if (errores == 0)
            $display(" RESULTADO: OK - %0d vectores sin discrepancias",
                     probados);
        else
            $display(" RESULTADO: FALLO - %0d discrepancias", errores);
        $display("==========================================================");

        $finish;
    end

endmodule

`default_nettype wire