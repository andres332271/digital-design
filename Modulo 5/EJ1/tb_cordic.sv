`timescale 1ns/1ps

module tb_cordic;
    localparam int N_ITER = 14;
    logic clk, rst, start;
    logic signed [15:0] theta;
    logic signed [15:0] x_f, y_f, theta_fin;
    logic busy, done;
    integer errors = 0;

    `include "cordic_expected.svh"

    cordic dut (
        .clk, .rst, .start, .theta,
        .x_f, .y_f, .theta_fin, .busy, .done
    );

    always #5 clk = ~clk;

    task automatic ejecutar_y_verificar(
        input logic signed [15:0] theta_in,
        input logic signed [15:0] cos_esperado,
        input logic signed [15:0] sen_esperado,
        input string nombre_caso
    );
        integer ciclos_iter;
        begin
            @(negedge clk);
            theta = theta_in;
            start = 1'b1;

            // IDLE captura theta y el datapath carga x=1/K, y=0, z=theta.
            @(posedge clk);
            @(negedge clk);
            start = 1'b0;

            ciclos_iter = 0;
            while (!done) begin
                @(posedge clk);
                if (busy) ciclos_iter = ciclos_iter + 1;
            end
            #1;

            if (x_f !== cos_esperado || y_f !== sen_esperado) begin
                errors = errors + 1;
                $display("ERROR [%s]: theta=%0d | cos esperado=%0d obtenido=%0d | sen esperado=%0d obtenido=%0d",
                         nombre_caso, theta_in, cos_esperado, x_f, sen_esperado, y_f);
            end else begin
                $display("OK [%s]: theta=%0d | cos=%0d, sen=%0d, residual=%0d",
                         nombre_caso, theta_in, x_f, y_f, theta_fin);
            end

            if (ciclos_iter != N_ITER) begin
                errors = errors + 1;
                $display("ERROR CICLOS [%s]: esperados=%0d obtenidos=%0d",
                         nombre_caso, N_ITER, ciclos_iter);
            end

            // DONE dura un ciclo; el siguiente flanco devuelve la FSM a IDLE.
            @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;
        theta = '0;

        $dumpfile("sim_cordic.vcd");
        $dumpvars(0, tb_cordic);

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        ejecutar_y_verificar(THETA_PI_6, EXP_COS_PI_6, EXP_SEN_PI_6, "pi/6");
        ejecutar_y_verificar(THETA_PI_4, EXP_COS_PI_4, EXP_SEN_PI_4, "pi/4");
        ejecutar_y_verificar(THETA_PI_3, EXP_COS_PI_3, EXP_SEN_PI_3, "pi/3");

        if (errors == 0)
            $display("PASS: pi/6, pi/4 y pi/3 coinciden con el modelo dorado; 14 ciclos verificados.");
        else
            $display("FAIL: %0d errores encontrados.", errors);
        $finish;
    end
endmodule
