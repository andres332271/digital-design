`timescale 1ns/1ps

module tb_pipeline;

    reg         clk = 0;
    reg         rst_n;
    reg  signed [7:0] x_in;
    reg         valid_in;
    wire        ready_out;

    wire signed [15:0] y_out;
    wire        valid_out;
    reg         ready_in;

    integer errors = 0;
    integer sent   = 0;
    integer recv   = 0;
    integer cycles_with_data = 0; // ciclos donde hubo transferencia de salida
    integer total_cycles = 0;

    // Cola de valores esperados (modelo simple con array + punteros)
    reg signed [15:0] expected_q [0:255];
    integer q_head = 0;
    integer q_tail = 0;

    // DUT
    pipeline_3stage dut (
        .clk(clk), .rst_n(rst_n),
        .x_in(x_in), .valid_in(valid_in), .ready_out(ready_out),
        .y_out(y_out), .valid_out(valid_out), .ready_in(ready_in)
    );

    // Golden model (función definida arriba, o incluida vía `include)
    function automatic signed [15:0] golden_model;
        input signed [7:0] x;
        reg signed [15:0] sum, prod;
        begin
            sum  = x + 8'sd5;
            prod = sum * 8'sd3;
            golden_model = prod >>> 4;
        end
    endfunction

    // Clock 100MHz
    always #5 clk = ~clk;

    // --- Empuje de expected a la cola cuando hay handshake de entrada ---
    always @(posedge clk) begin
        if (rst_n && valid_in && ready_out) begin
            expected_q[q_tail] <= golden_model(x_in);
            q_tail <= q_tail + 1;
            sent <= sent + 1;
        end
    end

    // --- Chequeo cuando hay handshake de salida ---
    always @(posedge clk) begin
        if (rst_n && valid_out && ready_in) begin
            if (y_out !== expected_q[q_head]) begin
                $display("[%0t] ERROR: y_out=%0d esperado=%0d (muestra #%0d)",
                          $time, y_out, expected_q[q_head], recv);
                errors = errors + 1;
            end
            q_head <= q_head + 1;
            recv <= recv + 1;
            cycles_with_data = cycles_with_data + 1;
        end
        if (rst_n) total_cycles = total_cycles + 1;
    end

    // --- Generación de estímulos ---
    integer i;
    initial begin
        rst_n    <= 0;
        valid_in <= 0;
        x_in     <= 0;
        ready_in <= 1;
        repeat (3) @(posedge clk);
        rst_n <= 1;
        @(posedge clk);

        // FASE 1: régimen continuo, sin stalls (para medir throughput teórico)
        valid_in <= 1;
        ready_in <= 1;
        for (i = 0; i < 50; i = i + 1) begin
            x_in <= $random;
            @(posedge clk);
        end

        // FASE 2: con stall — ready_in alternando 1/0
        for (i = 0; i < 50; i = i + 1) begin
            x_in     <= $random;
            valid_in <= 1;
            ready_in <= (i % 2 == 0); // alterna 1,0,1,0...
            @(posedge clk);
        end

        // FASE 3: drenar el pipeline
        valid_in <= 0;
        ready_in <= 1;
        repeat (10) @(posedge clk);

        // Reporte final
        $display("----------------------------------------");
        $display("Muestras enviadas:  %0d", sent);
        $display("Muestras recibidas: %0d", recv);
        $display("Errores:            %0d", errors);
        $display("Throughput observado: %0d datos / %0d ciclos = %.3f",
                   cycles_with_data, total_cycles,
                   cycles_with_data * 1.0 / total_cycles);
        $display("Throughput teorico (sin stall): 1.0 dato/ciclo");
        if (errors == 0 && sent == recv)
            $display("RESULTADO: PASS");
        else
            $display("RESULTADO: FAIL");
        $display("----------------------------------------");
        $finish;
    end

endmodule
