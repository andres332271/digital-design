`timescale 1ns/1ps

module tb_cordic_vectoring;
    localparam int N_ITER = 16;
    // Tolerancias contra la referencia matematica directa, en LSBs.
    localparam int MAX_R_ERROR_LSB = 8;
    localparam int MAX_PHI_ERROR_LSB = 8;

    logic clk = 1'b0, rst = 1'b1, start = 1'b0;
    logic signed [15:0] x_in, y_in, r;
    logic signed [17:0] phi, y_residual;
    logic busy, done;
    integer errors = 0;

    `include "cordic_vectoring_expected.svh"

    cordic_vectoring dut (
        .clk, .rst, .start, .x_in, .y_in, .r, .phi, .y_residual, .busy, .done
    );
    always #5 clk = ~clk;

    function automatic integer abs_int(input integer value);
        abs_int = (value < 0) ? -value : value;
    endfunction

    task automatic run_case(
        input logic signed [15:0] x_value,
        input logic signed [15:0] y_value,
        input logic signed [15:0] r_ref,
        input logic signed [17:0] phi_ref,
        input string name
    );
        integer iter_cycles;
        integer r_error, phi_error;
        begin
            @(negedge clk);
            x_in = x_value;
            y_in = y_value;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            iter_cycles = 0;
            while (!done) begin
                @(posedge clk);
                if (busy) iter_cycles = iter_cycles + 1;
            end
            #1;
            r_error = abs_int($signed(r) - $signed(r_ref));
            phi_error = abs_int($signed(phi) - $signed(phi_ref));
            if (iter_cycles != N_ITER || r_error > MAX_R_ERROR_LSB ||
                phi_error > MAX_PHI_ERROR_LSB) begin
                errors = errors + 1;
                $display("ERROR [%s]: ciclos=%0d R=%0d ref=%0d err=%0d phi=%0d ref=%0d err=%0d",
                         name, iter_cycles, r, r_ref, r_error, phi, phi_ref, phi_error);
            end else begin
                $display("OK [%s]: R=%0d (err %0d LSB), phi=%0d (err %0d LSB), residual_y=%0d",
                         name, r, r_error, phi, phi_error, y_residual);
            end
            @(posedge clk);
        end
    endtask

    initial begin
        x_in = '0;
        y_in = '0;
        $dumpfile("sim_cordic_vectoring.vcd");
        $dumpvars(0, tb_cordic_vectoring);
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        run_case(X_Q1, Y_Q1, R_REF_Q1, PHI_REF_Q1, "cuadrante I");
        run_case(X_Q2, Y_Q2, R_REF_Q2, PHI_REF_Q2, "cuadrante II");
        run_case(X_Q3, Y_Q3, R_REF_Q3, PHI_REF_Q3, "cuadrante III");
        run_case(X_Q4, Y_Q4, R_REF_Q4, PHI_REF_Q4, "cuadrante IV");
        run_case(X_EJE_X, Y_EJE_X, R_REF_EJE_X, PHI_REF_EJE_X, "eje X");
        run_case(X_EJE_Y, Y_EJE_Y, R_REF_EJE_Y, PHI_REF_EJE_Y, "eje Y negativo");

        if (errors == 0)
            $display("PASS: 4 cuadrantes, ejes y 16 iteraciones verificados.");
        else
            $fatal(1, "FAIL: %0d casos fuera de tolerancia.", errors);
        $finish;
    end
endmodule
