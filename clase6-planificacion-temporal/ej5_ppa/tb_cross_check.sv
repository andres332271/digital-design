`timescale 1ns/1ps
`default_nettype none

// Verificacion cruzada ej3 vs ej4: instancia fir_iter (folding, ej3) y
// fir_pipeline (retimeado, ej4) y les da la MISMA secuencia de muestras.
// No hay golden model propio -- lo que se prueba es que ambas arquitecturas,
// con paces (start/done vs. valid_in/valid_out) y latencias distintas,
// producen exactamente la misma secuencia de salida: la afirmacion central
// de ej4_pipeline/report.md ("distinta arquitectura, misma funcion de
// transferencia"), no solo cada una contra su propio golden model por
// separado (ver ej5_ppa/report.md / ej3_iterativo/report.md).
module tb_cross_check;

    localparam int N       = 4;
    localparam int DATA_W  = 8;
    localparam int ACC_W   = 2*DATA_W + $clog2(N);
    localparam int PERIODO = 10;
    localparam int N_MUESTRAS = 100;

    logic clk, rst_n;

    // --- DUT ej3: iterativo (start/done) ---
    logic                     start_iter;
    logic signed [DATA_W-1:0] x_iter;
    logic signed [ACC_W-1:0]  y_iter;
    logic                     done_iter, busy_iter;

    fir_iter #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) dut_iter (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start_iter),
        .x_in   (x_iter),
        .y      (y_iter),
        .done   (done_iter),
        .busy   (busy_iter)
    );

    // --- DUT ej4: pipeline (valid_in/valid_out, streaming) ---
    logic                     valid_in_pipe;
    logic signed [DATA_W-1:0] x_pipe;
    logic signed [ACC_W-1:0]  y_pipe;
    logic                     valid_out_pipe;

    fir_pipeline #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) dut_pipe (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in_pipe),
        .x_in      (x_pipe),
        .y         (y_pipe),
        .valid_out (valid_out_pipe)
    );

    initial clk = 1'b0;
    always #(PERIODO/2) clk = ~clk;

    // Misma secuencia de muestras para los dos DUTs (semilla fija).
    logic signed [DATA_W-1:0] muestras [0:N_MUESTRAS-1];

    // Cada DUT llena su propia cola de resultados, en orden.
    longint q_iter [$];
    longint q_pipe [$];

    always_ff @(posedge clk) if (done_iter)      q_iter.push_back(longint'($signed(y_iter)));
    always_ff @(posedge clk) if (valid_out_pipe) q_pipe.push_back(longint'($signed(y_pipe)));

    // Driver ej3: un start por muestra, esperando el done de la anterior
    // (mismo protocolo que tb_fir_iter.sv).
    task automatic correr_iter();
        begin
            for (int i = 0; i < N_MUESTRAS; i++) begin
                @(negedge clk);
                x_iter     = muestras[i];
                start_iter = 1'b1;
                @(negedge clk);
                start_iter = 1'b0;
                wait (done_iter);
                @(negedge clk);
            end
        end
    endtask

    // Driver ej4: streaming, una muestra por ciclo, sin esperar nada.
    task automatic correr_pipe();
        begin
            for (int i = 0; i < N_MUESTRAS; i++) begin
                @(negedge clk);
                x_pipe        = muestras[i];
                valid_in_pipe = 1'b1;
            end
            @(negedge clk);
            valid_in_pipe = 1'b0;
        end
    endtask

    int errores;
    integer seed = 1;

    initial begin
        $dumpfile("tb_cross_check.vcd");
        $dumpvars(0, tb_cross_check);

        $display("==================================================================");
        $display(" Cross-check: fir_iter (ej3) vs fir_pipeline (ej4), misma secuencia");
        $display("==================================================================");

        for (int i = 0; i < N_MUESTRAS; i++)
            muestras[i] = DATA_W'($signed($random(seed)) % 128);

        rst_n         = 1'b0;
        start_iter    = 1'b0;
        valid_in_pipe = 1'b0;
        x_iter        = '0;
        x_pipe        = '0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        // Los dos drivers corren en paralelo -- son independientes, cada uno
        // a su propio ritmo. Se espera a que ambas colas tengan los
        // N_MUESTRAS resultados.
        fork
            correr_iter();
            correr_pipe();
        join

        // Drenar el pipeline (por si el ultimo valid_out todavia no llego).
        repeat (2*N) @(negedge clk);

        $display("  muestras enviadas:        %0d", N_MUESTRAS);
        $display("  resultados ej3 (iter):    %0d", q_iter.size());
        $display("  resultados ej4 (pipe):    %0d", q_pipe.size());

        errores = 0;
        if (q_iter.size() != N_MUESTRAS || q_pipe.size() != N_MUESTRAS) begin
            $display("  ERROR: alguna cola no junto las %0d muestras esperadas", N_MUESTRAS);
            errores++;
        end else begin
            for (int i = 0; i < N_MUESTRAS; i++) begin
                if (q_iter[i] !== q_pipe[i]) begin
                    $display("  ERROR: muestra %0d - ej3=%0d ej4=%0d", i, q_iter[i], q_pipe[i]);
                    errores++;
                end
            end
        end

        $display("");
        $display("==================================================================");
        if (errores == 0)
            $display(" RESULTADO: OK - ej3 y ej4 calculan EXACTAMENTE la misma secuencia");
        else
            $display(" RESULTADO: FALLO - %0d discrepancias entre ej3 y ej4", errores);
        $display("==================================================================");

        $finish;
    end

    initial begin
        #(PERIODO * 200000);
        $display(" ERROR: watchdog - la simulacion no termino a tiempo");
        $finish;
    end

endmodule

`default_nettype wire
