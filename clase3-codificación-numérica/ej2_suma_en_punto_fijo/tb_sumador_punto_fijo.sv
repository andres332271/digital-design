`timescale 1ns/1ps
`default_nettype none

// Self-checking: lee a.hex / b.hex / expected.hex (generados por gen_vectors.py
// con fxpmath como referencia "golden") y compara contra la salida del DUT.
module tb_sumador_punto_fijo;

    localparam int NBA  = 6;
    localparam int NBFA = 4;
    localparam int NBB  = 8;
    localparam int NBFB = 5;
    localparam int NBS  = 9;

    localparam int MAX_VECTORES = 20000;

    logic signed [NBA-1:0] a_mem [0:MAX_VECTORES-1];
    logic signed [NBB-1:0] b_mem [0:MAX_VECTORES-1];
    logic signed [NBS-1:0] exp_mem [0:MAX_VECTORES-1];

    logic signed [NBA-1:0] a;
    logic signed [NBB-1:0] b;
    wire  signed [NBS-1:0] sum;

    int errores = 0;
    int n_vectores;

    sumador_punto_fijo #(
        .NBA(NBA), .NBFA(NBFA), .NBB(NBB), .NBFB(NBFB)
    ) dut (
        .a   (a),
        .b   (b),
        .sum (sum)
    );

    initial begin
        $dumpfile("tb_sumador_punto_fijo.vcd");
        $dumpvars(0, tb_sumador_punto_fijo);

        $readmemh("a.hex", a_mem);
        $readmemh("b.hex", b_mem);
        $readmemh("expected.hex", exp_mem);

        // a.hex fue generado con valores válidos; cuenta hasta el primer hueco sin llenar.
        n_vectores = 0;
        while (n_vectores < MAX_VECTORES && !$isunknown(a_mem[n_vectores]))
            n_vectores++;

        $display("==========================================================");
        $display(" Ejercicio 2 - Suma en punto fijo signado");
        $display(" S(%0d,%0d) + S(%0d,%0d) -> S(%0d,%0d)  |  %0d vectores",
                  NBA, NBFA, NBB, NBFB, NBS, NBFA > NBFB ? NBFA : NBFB, n_vectores);
        $display("==========================================================");

        for (int i = 0; i < n_vectores; i++) begin
            a = a_mem[i];
            b = b_mem[i];
            #1;
            if (sum !== exp_mem[i]) begin
                $display("  ERROR vector %0d: a=%0d b=%0d  esperado=%0d  obtenido=%0d",
                          i, a, b, exp_mem[i], sum);
                errores++;
            end
        end

        $display("");
        if (errores == 0)
            $display(" RESULTADO: OK - %0d vectores sin discrepancias", n_vectores);
        else
            $display(" RESULTADO: FALLO - %0d/%0d discrepancias", errores, n_vectores);
        $display("==========================================================");

        $finish;
    end

endmodule

`default_nettype wire
