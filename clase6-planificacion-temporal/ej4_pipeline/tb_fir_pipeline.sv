`timescale 1ns/1ps
`default_nettype none

// Self-checking: golden model embebido (misma linea de retardo y mismos coeficientes
// que fir_pipeline.sv) comparado contra el DUT en regimen de streaming (una muestra
// nueva por ciclo, back-to-back). Cola FIFO de valores esperados: el pipeline es
// in-order, asi que el primer valid_out siempre corresponde a la primera muestra
// todavia no consumida.
module tb_fir_pipeline;

    localparam int N       = 4;
    localparam int DATA_W  = 8;
    localparam int ACC_W   = 2*DATA_W + $clog2(N);
    localparam int PERIODO = 10;
    int N_ALEATORIOS = 200; // default; override con +N_VECTORS=<n> (ver run.sh)

    // Debe coincidir exactamente con la funcion coef() de fir_pipeline.sv.
    function automatic logic signed [DATA_W-1:0] coef_ref(input int i);
        case (i)
            0: coef_ref = 8'sd17;
            1: coef_ref = -8'sd23;
            2: coef_ref = 8'sd41;
            3: coef_ref = -8'sd5;
            default: coef_ref = '0;
        endcase
    endfunction

    logic                      clk;
    logic                      rst_n;
    logic                      valid_in;
    logic signed [DATA_W-1:0]  x_in;
    logic signed [ACC_W-1:0]   y;
    logic                      valid_out;

    int errores        = 0;
    int comparados     = 0;
    int total_muestras;
    integer seed       = 1;

    initial clk = 1'b0;
    always #(PERIODO/2) clk = ~clk;

    fir_pipeline #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .x_in      (x_in),
        .y         (y),
        .valid_out (valid_out)
    );

    logic signed [DATA_W-1:0] modelo_taps [0:N-1];
    longint esperado_q [$];

    // Checker concurrente: cada valid_out consume el frente de la cola.
    always_ff @(posedge clk) begin
        if (rst_n && valid_out) begin
            longint esperado;
            if (esperado_q.size() == 0) begin
                $display("  ERROR: valid_out sin muestra pendiente en la cola");
                errores++;
            end else begin
                esperado = esperado_q.pop_front();
                comparados++;
                if (longint'($signed(y)) !== esperado) begin
                    $display("  ERROR: esperado=%0d obtenido=%0d", esperado, $signed(y));
                    errores++;
                end
            end
        end
    end

    task automatic aplicar(input int muestra);
        longint esperado_l;
        begin
            for (int i = N-1; i > 0; i--) modelo_taps[i] = modelo_taps[i-1];
            modelo_taps[0] = DATA_W'(muestra);

            esperado_l = 0;
            for (int i = 0; i < N; i++)
                esperado_l += longint'(coef_ref(i)) * longint'(modelo_taps[i]);
            esperado_q.push_back(esperado_l);

            x_in     = DATA_W'(muestra);
            valid_in = 1'b1;
        end
    endtask

    initial begin
        $dumpfile("tb_fir_pipeline.vcd");
        $dumpvars(0, tb_fir_pipeline);

        $display("==================================================================");
        $display(" Ejercicio 4 - FIR pipeline retimeado (2 etapas, streaming, N=%0d)", N);
        $display("==================================================================");
        $display("");

        for (int i = 0; i < N; i++) modelo_taps[i] = '0;
        void'($value$plusargs("N_VECTORS=%d", N_ALEATORIOS));

        rst_n    = 1'b0;
        valid_in = 1'b0;
        x_in     = '0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        // Extremos reales del acumulador para H={17,-23,41,-5} (mismo calculo que
        // ej3_iterativo/tb_fir_iter.sv): tras 4 muestras back-to-back, la ventana
        // queda fija en el combo pedido, sin importar el estado previo.
        // Mismo patron "esperar y luego aplicar" que el loop de abajo -- SIN
        // wait extra despues del ultimo aplicar(), o valid_in queda en alto
        // un ciclo de mas con x_in viejo y cuela una muestra fantasma.
        $display("--- Extremo positivo del acumulador (+10950, de 18 bits = +-131071) ---");
        @(negedge clk); aplicar(-128);
        @(negedge clk); aplicar(127);
        @(negedge clk); aplicar(-128);
        @(negedge clk); aplicar(127);
        $display("--- Extremo negativo del acumulador (-10980) ---");
        @(negedge clk); aplicar(127);
        @(negedge clk); aplicar(-128);
        @(negedge clk); aplicar(127);
        @(negedge clk); aplicar(-128);
        $display("");

        $display("--- %0d muestras back-to-back (valid_in=1 todos los ciclos) ---",
                  N_ALEATORIOS);
        for (int i = 0; i < N_ALEATORIOS; i++) begin
            @(negedge clk);
            aplicar($signed($random(seed)) % 128);
        end

        @(negedge clk);
        valid_in = 1'b0;
        x_in     = '0;

        // Drenar el pipeline (2 etapas -> a lo sumo unos pocos ciclos de margen).
        repeat (2*N) @(negedge clk);

        total_muestras = N_ALEATORIOS + 8; // 8 = las dirigidas a extremos, arriba
        $display("  muestras aplicadas:   %0d", total_muestras);
        $display("  resultados comparados: %0d", comparados);
        $display("  muestras sin drenar:   %0d", esperado_q.size());
        $display("");
        $display("==================================================================");
        if (errores == 0 && comparados == total_muestras && esperado_q.size() == 0)
            $display(" RESULTADO: OK - sin discrepancias, pipeline totalmente drenado");
        else
            $display(" RESULTADO: FALLO - %0d discrepancias, %0d/%0d comparados, %0d sin drenar",
                      errores, comparados, total_muestras, esperado_q.size());
        $display(" LATENCIA: 2 ciclos (valid_in -> valid_out), fija por construccion (streaming)");
        $display(" THROUGHPUT: 1 muestra/ciclo en regimen permanente (medido: %0d muestras en %0d ciclos back-to-back)",
                  N_ALEATORIOS, N_ALEATORIOS);
        $display("==================================================================");

        $finish;
    end

    initial begin
        #(PERIODO * 100000);
        $display(" ERROR: watchdog - la simulacion no termino a tiempo");
        $finish;
    end

endmodule

`default_nettype wire
