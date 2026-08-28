`timescale 1ns/1ps

// Verifica flujo continuo: tres muestras consecutivas y los huecos de valid.
module tb_cordic_pipeline;
    localparam int LATENCY = 14;
    logic clk = 1'b0;
    logic rst;
    logic valid_in;
    logic signed [15:0] theta;
    logic valid_out;
    logic signed [15:0] cos_theta, sen_theta, theta_fin;
    int errors = 0;
    int cycle = 0;
    int accepted_cycle [0:2];
    int output_count = 0;

    cordic_pipeline dut (
        .clk, .rst, .valid_in, .theta, .valid_out,
        .cos_theta, .sen_theta, .theta_fin
    );

    always #5 clk = ~clk;
    always @(posedge clk) cycle = cycle + 1;

    task automatic drive(input logic v, input logic signed [15:0] angle);
        @(negedge clk);
        valid_in = v;
        theta = angle;
    endtask

    always @(negedge clk) begin
        if (valid_out) begin
            if (cycle - accepted_cycle[output_count] != LATENCY) begin
                errors = errors + 1;
                $display("ERROR latencia: esperados=%0d obtenidos=%0d", LATENCY,
                         cycle - accepted_cycle[output_count]);
            end
            case (output_count)
                0: check_output(16'sd14191, 16'sd8189,  16'sd1,  "pi/6");
                1: check_output(16'sd11586, 16'sd11585, 16'sd0,  "pi/4");
                2: check_output(16'sd8189,  16'sd14191, -16'sd1, "pi/3");
                default: begin
                    errors = errors + 1;
                    $display("ERROR: salida valida inesperada");
                end
            endcase
            output_count = output_count + 1;
        end
    end

    task automatic check_output(
        input logic signed [15:0] exp_cos,
        input logic signed [15:0] exp_sen,
        input logic signed [15:0] exp_residual,
        input string name
    );
        begin
            if (cos_theta !== exp_cos || sen_theta !== exp_sen ||
                theta_fin !== exp_residual) begin
                errors = errors + 1;
                $display("ERROR [%s]: cos=%0d/%0d sen=%0d/%0d z=%0d/%0d",
                    name, cos_theta, exp_cos, sen_theta, exp_sen,
                    theta_fin, exp_residual);
            end else begin
                $display("OK [%s]: cos=%0d sen=%0d residual=%0d",
                    name, cos_theta, sen_theta, theta_fin);
            end
        end
    endtask

    initial begin
        rst = 1'b1;
        valid_in = 1'b0;
        theta = '0;
        $dumpfile("sim_cordic_pipeline.vcd");
        $dumpvars(0, tb_cordic_pipeline);

        repeat (2) @(negedge clk);
        rst = 1'b0;

        // El pipeline acepta una muestra por ciclo.
        drive(1'b1, 16'sd8579);  accepted_cycle[0] = cycle + 1;
        drive(1'b1, 16'sd12868); accepted_cycle[1] = cycle + 1;
        drive(1'b1, 16'sd17157); accepted_cycle[2] = cycle + 1;
        drive(1'b0, '0);

        repeat (LATENCY + 3) @(negedge clk);
        if (output_count != 3) begin
            errors = errors + 1;
            $display("ERROR: se esperaban 3 salidas, se recibieron %0d", output_count);
        end
        if (errors == 0)
            $display("PASS: 3 muestras consecutivas verificadas; latencia configurada: %0d ciclos.", LATENCY);
        else
            $fatal(1, "FAIL: %0d errores.", errors);
        $finish;
    end
endmodule
