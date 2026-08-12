`timescale 1ns/1ps
`default_nettype none

module tb_CSD_recodificacion;

    localparam int WIDTH = 8;
    localparam int OUTW  = WIDTH + 5;
    localparam int K     = 23;

    logic signed [WIDTH-1:0] x;
    logic signed [OUTW-1:0]  y_bin;
    logic signed [OUTW-1:0]  y_csd;
    logic signed [OUTW-1:0]  y_ref;

    int errores = 0;

    localparam int N_CASOS = 8;
    int casos [N_CASOS];

    mult_K23_bin #(.WIDTH(WIDTH)) dut_bin (
        .x (x),
        .y (y_bin)
    );

    CSD_recodificacion #(.WIDTH(WIDTH)) dut_csd (
        .x (x),
        .y (y_csd)
    );

    task automatic verificar(input int valor);
        begin
            x = WIDTH'(valor);
            #1;
            y_ref = OUTW'(valor * K);

            if (y_bin !== y_ref) begin
                $display("  ERROR binario   : x=%0d  esperado=%0d  obtenido=%0d",
                         valor, y_ref, y_bin);
                errores++;
            end

            if (y_csd !== y_ref) begin
                $display("  ERROR CSD       : x=%0d  esperado=%0d  obtenido=%0d",
                         valor, y_ref, y_csd);
                errores++;
            end

            if (y_bin !== y_csd) begin
                $display("  ERROR equivalencia: x=%0d  bin=%0d  csd=%0d",
                         valor, y_bin, y_csd);
                errores++;
            end
        end
    endtask

    //--------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_CSD_recodificacion.vcd");
        $dumpvars(0, tb_CSD_recodificacion);

        $display("==========================================================");
        $display(" Ejercicio 4 - Multiplicacion por constante K = %0d", K);
        $display("==========================================================");
        $display(" Binario : Y = (X<<4) + (X<<2) + (X<<1) + X   [4 terminos]");
        $display(" CSD     : Y = (X<<5) - (X<<3) - X            [3 terminos]");
        $display("");


        casos[0] =    0; casos[1] =    1; casos[2] =   -1; casos[3] =    5;
        casos[4] =   -5; casos[5] =   10; casos[6] =  100; casos[7] = -100;

        $display("--- Casos ilustrativos ---");
        for (int i = 0; i < N_CASOS; i++) begin
            verificar(casos[i]);
            $display("  x = %5d  ->  y_bin = %6d   y_csd = %6d   ref = %6d",
                     casos[i], y_bin, y_csd, y_ref);
        end
        $display("");


        $display("--- Casos limite del rango [%0d, %0d] ---",
                 -(2**(WIDTH-1)), 2**(WIDTH-1)-1);

        verificar(-(2**(WIDTH-1)));
        $display("  x = %5d  ->  y_csd = %6d   (esperado %0d)",
                 x, y_csd, -(2**(WIDTH-1)) * K);

        verificar(2**(WIDTH-1) - 1);
        $display("  x = %5d  ->  y_csd = %6d   (esperado %0d)",
                 x, y_csd, (2**(WIDTH-1) - 1) * K);
        $display("");


        $display("--- Barrido exhaustivo: %0d vectores ---", 2**WIDTH);

        for (int i = -(2**(WIDTH-1)); i < 2**(WIDTH-1); i++) begin
            verificar(i);
        end

        $display("");
        $display("==========================================================");
        if (errores == 0)
            $display(" RESULTADO: OK - %0d vectores sin discrepancias", 2**WIDTH);
        else
            $display(" RESULTADO: FALLO - %0d discrepancias", errores);
        $display("==========================================================");

        $finish;
    end

endmodule

`default_nettype wire