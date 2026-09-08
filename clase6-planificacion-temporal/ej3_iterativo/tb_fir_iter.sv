`timescale 1ns/1ps
`default_nettype none

// Self-checking: golden model embebido (misma linea de retardo y mismos
// coeficientes que fir_iter.sv, replicados aca) comparado contra el DUT.
// Ademas mide ciclos de latencia (via dut.busy) y throughput real entre
// starts consecutivos (via dut.done).
module tb_fir_iter;

    localparam int N       = 4;
    localparam int DATA_W  = 8;
    localparam int ACC_W   = 2*DATA_W + $clog2(N);
    localparam int PERIODO = 10;
    int N_ALEATORIOS = 200; // default; override con +N_VECTORS=<n> (ver run.sh)

    // Debe coincidir exactamente con la funcion coef() de fir_iter.sv.
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
    logic                      start;
    logic signed [DATA_W-1:0]  x_in;
    logic signed [ACC_W-1:0]   y;
    logic                      done, busy;

    int errores    = 0;
    int probados   = 0;
    int ciclos_mal = 0;
    integer seed   = 1;

    initial clk = 1'b0;
    always #(PERIODO/2) clk = ~clk;

    fir_iter #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start),
        .x_in   (x_in),
        .y      (y),
        .done   (done),
        .busy   (busy)
    );

    // Cuenta ciclos de COMPUTE de la muestra en curso (latencia real medida).
    logic [7:0] ciclos_op;
    always_ff @(posedge clk) begin
        if (dut.load)      ciclos_op <= '0;
        else if (dut.busy) ciclos_op <= ciclos_op + 8'd1;
    end

    // Modelo de referencia de la linea de retardo: misma semantica de shift que el DUT.
    logic signed [DATA_W-1:0] modelo_taps [0:N-1];

    task automatic aplicar_muestra(
        input  int      muestra,
        output longint  resultado,
        output int      ciclos
    );
        begin
            @(negedge clk);
            x_in  = DATA_W'(muestra);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            wait (done);
            resultado = longint'($signed(y));
            ciclos    = int'(ciclos_op);

            @(negedge clk); // ciclo de S_DONE -> S_IDLE antes del proximo start
        end
    endtask

    task automatic verificar(input int muestra);
        longint obtenido, esperado_l;
        int     esperado;
        int     ciclos;
        begin
            // Shiftear el modelo ANTES de calcular, misma semantica que "load" en el DUT.
            for (int i = N-1; i > 0; i--) modelo_taps[i] = modelo_taps[i-1];
            modelo_taps[0] = DATA_W'(muestra);

            esperado_l = 0;
            for (int i = 0; i < N; i++)
                esperado_l += longint'(coef_ref(i)) * longint'(modelo_taps[i]);
            esperado = int'(esperado_l);

            aplicar_muestra(muestra, obtenido, ciclos);
            probados++;

            if (obtenido !== longint'(esperado)) begin
                $display("  ERROR: x=%0d  esperado=%0d  obtenido=%0d",
                          muestra, esperado, obtenido);
                errores++;
            end
            if (ciclos != N) begin
                $display("  ERROR ciclos: x=%0d tardo %0d ciclos (esperado %0d)",
                          muestra, ciclos, N);
                ciclos_mal++;
            end
        end
    endtask

    time t_inicio, t_fin;
    real ciclos_por_muestra;

    initial begin
        $dumpfile("tb_fir_iter.vcd");
        $dumpvars(0, tb_fir_iter);

        $display("==================================================================");
        $display(" Ejercicio 3 - FIR iterativo (1 mult + 1 add compartidos, N=%0d)", N);
        $display("==================================================================");
        $display("");

        for (int i = 0; i < N; i++) modelo_taps[i] = '0;
        void'($value$plusargs("N_VECTORS=%d", N_ALEATORIOS));

        rst_n = 1'b0;
        start = 1'b0;
        x_in  = '0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        $display("--- Casos limite ---");
        verificar(0);
        verificar(127);
        verificar(-128);
        verificar(1);
        verificar(-1);

        // Extremos reales del acumulador para H={17,-23,41,-5} (no un generico
        // "cerca de 2^17"): se calculan a mano combinando el signo de x[n-i]
        // con el signo de cada coeficiente para maximizar |suma|.
        // Positivo: taps=(x[n]=127,x[n-1]=-128,x[n-2]=127,x[n-3]=-128) -> +10950.
        $display("--- Extremo positivo del acumulador (+10950, de 18 bits = +-131071) ---");
        verificar(-128);
        verificar(127);
        verificar(-128);
        verificar(127);
        // Negativo: taps=(x[n]=-128,x[n-1]=127,x[n-2]=-128,x[n-3]=127) -> -10980.
        $display("--- Extremo negativo del acumulador (-10980) ---");
        verificar(127);
        verificar(-128);
        verificar(127);
        verificar(-128);
        $display("");

        $display("--- %0d muestras pseudoaleatorias (semilla fija, ventana deslizante) ---",
                  N_ALEATORIOS);
        // Muestras consecutivas sin idle extra: el gap entre verificar() es el
        // minimo que la FSM permite (grace cycle de S_DONE->S_IDLE), asi que el
        // tiempo total de este bloque / N_ALEATORIOS es el throughput real medido.
        t_inicio = $time;
        for (int i = 0; i < N_ALEATORIOS; i++) begin
            verificar($signed($random(seed)) % 128);
        end
        t_fin = $time;
        ciclos_por_muestra = real'(t_fin - t_inicio) / real'(PERIODO) / real'(N_ALEATORIOS);

        $display("  muestras verificadas: %0d", probados);
        $display("");
        $display("==================================================================");
        if (errores == 0)
            $display(" RESULTADO: OK - sin discrepancias");
        else
            $display(" RESULTADO: FALLO - %0d discrepancias", errores);

        if (ciclos_mal == 0)
            $display(" LATENCIA: OK - %0d ciclos constantes en las %0d muestras", N, probados);
        else
            $display(" LATENCIA: FALLO - %0d muestras con ciclos distintos de %0d", ciclos_mal, N);

        $display(" THROUGHPUT: %.2f ciclos/muestra medidos (back-to-back, %0d muestras)",
                  ciclos_por_muestra, N_ALEATORIOS);
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
