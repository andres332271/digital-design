`timescale 1ns/1ps
`default_nettype none

// Self-checking: lee x.hex/y.hex y los expected_*.hex (generados por gen_vectors.py
// con fxpmath como referencia "golden") y compara contra los 4 DUT.
module tb_recorte_punto_fijo;

    localparam int NBI_X_IN = 4, NBF_X_IN = 6, NBI_X_OUT = 4, NBF_X_OUT = 3;
    localparam int NBI_Y_IN = 5, NBF_Y_IN = 6, NBI_Y_OUT = 2, NBF_Y_OUT = 3;

    localparam int MAX_VECTORES = 20000;

    logic signed [NBI_X_IN+NBF_X_IN-1:0] x_mem [0:MAX_VECTORES-1];
    logic signed [NBI_X_OUT+NBF_X_OUT-1:0] exp_x_trunc_mem [0:MAX_VECTORES-1];
    logic signed [NBI_X_OUT+NBF_X_OUT-1:0] exp_x_round_mem [0:MAX_VECTORES-1];

    logic signed [NBI_Y_IN+NBF_Y_IN-1:0] y_mem [0:MAX_VECTORES-1];
    logic signed [NBI_Y_OUT+NBF_Y_OUT-1:0] exp_y_wrap_mem [0:MAX_VECTORES-1];
    logic signed [NBI_Y_OUT+NBF_Y_OUT-1:0] exp_y_sat_mem [0:MAX_VECTORES-1];

    logic signed [NBI_X_IN+NBF_X_IN-1:0] x;
    logic signed [NBI_Y_IN+NBF_Y_IN-1:0] y;
    wire  signed [NBI_X_OUT+NBF_X_OUT-1:0] x_trunc, x_round;
    wire  signed [NBI_Y_OUT+NBF_Y_OUT-1:0] y_wrap, y_sat;

    int errores = 0;
    int n_x, n_y;

    recorte_punto_fijo #(
        .NBI_IN(NBI_X_IN), .NBF_IN(NBF_X_IN), .NBI_OUT(NBI_X_OUT), .NBF_OUT(NBF_X_OUT),
        .ROUND_EN(1'b0), .SAT_EN(1'b0)
    ) dut_x_trunc (.x(x), .y(x_trunc));

    recorte_punto_fijo #(
        .NBI_IN(NBI_X_IN), .NBF_IN(NBF_X_IN), .NBI_OUT(NBI_X_OUT), .NBF_OUT(NBF_X_OUT),
        .ROUND_EN(1'b1), .SAT_EN(1'b0)
    ) dut_x_round (.x(x), .y(x_round));

    recorte_punto_fijo #(
        .NBI_IN(NBI_Y_IN), .NBF_IN(NBF_Y_IN), .NBI_OUT(NBI_Y_OUT), .NBF_OUT(NBF_Y_OUT),
        .ROUND_EN(1'b0), .SAT_EN(1'b0)
    ) dut_y_wrap (.x(y), .y(y_wrap));

    recorte_punto_fijo #(
        .NBI_IN(NBI_Y_IN), .NBF_IN(NBF_Y_IN), .NBI_OUT(NBI_Y_OUT), .NBF_OUT(NBF_Y_OUT),
        .ROUND_EN(1'b0), .SAT_EN(1'b1)
    ) dut_y_sat (.x(y), .y(y_sat));

    initial begin
        $dumpfile("tb_recorte_punto_fijo.vcd");
        $dumpvars(0, tb_recorte_punto_fijo);

        $readmemh("x.hex", x_mem);
        $readmemh("expected_x_trunc.hex", exp_x_trunc_mem);
        $readmemh("expected_x_round.hex", exp_x_round_mem);
        $readmemh("y.hex", y_mem);
        $readmemh("expected_y_wrap.hex", exp_y_wrap_mem);
        $readmemh("expected_y_sat.hex", exp_y_sat_mem);

        n_x = 0;
        while (n_x < MAX_VECTORES && !$isunknown(x_mem[n_x])) n_x++;
        n_y = 0;
        while (n_y < MAX_VECTORES && !$isunknown(y_mem[n_y])) n_y++;

        $display("==========================================================");
        $display(" Ejercicio 3 - Truncado, redondeo y saturacion");
        $display(" x: S(%0d,%0d) -> S(%0d,%0d)  trunc vs round | %0d vectores",
                  NBI_X_IN, NBF_X_IN, NBI_X_OUT, NBF_X_OUT, n_x);
        $display(" y: S(%0d,%0d) -> S(%0d,%0d)  wrap  vs sat   | %0d vectores",
                  NBI_Y_IN, NBF_Y_IN, NBI_Y_OUT, NBF_Y_OUT, n_y);
        $display("==========================================================");

        for (int i = 0; i < n_x; i++) begin
            x = x_mem[i];
            #1;
            if (x_trunc !== exp_x_trunc_mem[i]) begin
                $display("  ERROR x_trunc vector %0d: x=%0d esperado=%0d obtenido=%0d",
                          i, x, exp_x_trunc_mem[i], x_trunc);
                errores++;
            end
            if (x_round !== exp_x_round_mem[i]) begin
                $display("  ERROR x_round vector %0d: x=%0d esperado=%0d obtenido=%0d",
                          i, x, exp_x_round_mem[i], x_round);
                errores++;
            end
        end

        for (int i = 0; i < n_y; i++) begin
            y = y_mem[i];
            #1;
            if (y_wrap !== exp_y_wrap_mem[i]) begin
                $display("  ERROR y_wrap vector %0d: y=%0d esperado=%0d obtenido=%0d",
                          i, y, exp_y_wrap_mem[i], y_wrap);
                errores++;
            end
            if (y_sat !== exp_y_sat_mem[i]) begin
                $display("  ERROR y_sat vector %0d: y=%0d esperado=%0d obtenido=%0d",
                          i, y, exp_y_sat_mem[i], y_sat);
                errores++;
            end
        end

        $display("");
        if (errores == 0)
            $display(" RESULTADO: OK - %0d vectores sin discrepancias", n_x + n_y);
        else
            $display(" RESULTADO: FALLO - %0d discrepancias", errores);
        $display("==========================================================");

        $finish;
    end

endmodule

`default_nettype wire
