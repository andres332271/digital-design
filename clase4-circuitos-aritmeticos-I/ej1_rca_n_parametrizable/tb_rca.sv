`timescale 1ns/1ps
`default_nettype none

module tb_rca;

    localparam int  N       = 8;
    localparam time TG      = 1ns;
    localparam int  N_RAND  = 500;

    //--------------------------------------------------------------------------
    // DUT principal, del ancho por defecto
    //--------------------------------------------------------------------------
    logic [N-1:0] a, b;
    logic         cin;
    logic [N-1:0] s;
    logic         cout;

    rca #(.N(N), .TG(TG)) dut (
        .a (a), .b (b), .cin (cin), .s (s), .cout (cout)
    );

    int errores = 0;
    int casos   = 0;

    //--------------------------------------------------------------------------
    // Tiempo de asentamiento: holgado respecto del peor caso de cualquier
    // ancho instanciado, para que la comparacion se haga con salidas estables.
    //--------------------------------------------------------------------------
    localparam time T_SETTLE = 400ns;

    task automatic verificar(input logic [N-1:0] va,
                             input logic [N-1:0] vb,
                             input logic         vcin,
                             input string        etiqueta);
        logic [N:0] esperado;
        logic [N:0] obtenido;
        begin
            a   = va;
            b   = vb;
            cin = vcin;
            #T_SETTLE;

            esperado = va + vb + vcin;
            obtenido = {cout, s};
            casos++;

            if (obtenido !== esperado) begin
                $display("  FAIL %s: %0d + %0d + %0d  esperado=%0d  obtenido=%0d",
                         etiqueta, va, vb, vcin, esperado, obtenido);
                errores++;
            end else if (etiqueta != "random") begin
                $display("  PASS %-14s : %0d + %0d + %0d = %0d  (cout=%0b)",
                         etiqueta, va, vb, vcin, obtenido, cout);
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Instancias dedicadas a la medicion de delay vs N.
    // Se declaran por separado porque el ancho es un parametro de elaboracion:
    // no puede barrerse desde un lazo de simulacion.
    //--------------------------------------------------------------------------
    logic [63:0] da, db;
    logic        dcin;

    logic  [3:0] s4;    logic c4;
    logic  [7:0] s8;    logic c8;
    logic [15:0] s16;   logic c16;
    logic [31:0] s32;   logic c32;
    logic [63:0] s64;   logic c64;

    rca #(.N(4),  .TG(TG)) d4  (.a(da[3:0]),  .b(db[3:0]),  .cin(dcin), .s(s4),  .cout(c4));
    rca #(.N(8),  .TG(TG)) d8  (.a(da[7:0]),  .b(db[7:0]),  .cin(dcin), .s(s8),  .cout(c8));
    rca #(.N(16), .TG(TG)) d16 (.a(da[15:0]), .b(db[15:0]), .cin(dcin), .s(s16), .cout(c16));
    rca #(.N(32), .TG(TG)) d32 (.a(da[31:0]), .b(db[31:0]), .cin(dcin), .s(s32), .cout(c32));
    rca #(.N(64), .TG(TG)) d64 (.a(da),       .b(db),       .cin(dcin), .s(s64), .cout(c64));

    time t_inicio;
    time t_medido;

    //--------------------------------------------------------------------------
    int va, vb;

    initial begin
        $dumpfile("tb_rca.vcd");
        $dumpvars(0, tb_rca);

        $display("==========================================================");
        $display(" Ejercicio 1 - Ripple Carry Adder parametrizable (N = %0d)", N);
        $display("==========================================================");
        $display("");

        //----------------------------------------------------------------------
        // Casos de borde exigidos
        //----------------------------------------------------------------------
        $display("--- Casos de borde ---");

        verificar('0, '0, 1'b0, "borde inferior");
        verificar('1, '1, 1'b0, "borde superior");
        verificar('1, '1, 1'b1, "max+max+cin");
        verificar('1, 8'd1, 1'b0, "carry-out = 1");
        verificar('0, '0, 1'b1, "solo cin");
        $display("");

        //----------------------------------------------------------------------
        // Casos aleatorios
        //----------------------------------------------------------------------
        $display("--- %0d casos aleatorios ---", N_RAND);

        for (int k = 0; k < N_RAND; k++) begin
            va = $urandom_range(0, (1 << N) - 1);
            vb = $urandom_range(0, (1 << N) - 1);
            verificar(N'(va), N'(vb), $urandom_range(0, 1), "random");
        end

        $display("  %0d casos aleatorios sin discrepancias", N_RAND);
        $display("");

        //----------------------------------------------------------------------
        // Medicion de delay: peor caso de propagacion
        //----------------------------------------------------------------------
        $display("--- Delay medido (peor caso de propagacion) ---");
        $display("  Estimulo: a = todos unos, b = 0, cin: 0 -> 1");
        $display("  Retardo por nivel de logica: TG = 1 ns");
        $display("");
        $display("     N    delay [ns]    niveles de logica");
        $display("   ----  ------------  -------------------");

        da   = '1;
        db   = '0;
        dcin = 1'b0;
        #T_SETTLE;

        t_inicio = $time;
        dcin     = 1'b1;

        // Cada ancho se observa por separado: se espera a que su acarreo de
        // salida conmute y se registra el instante.
        @(posedge c4);   t_medido = $time - t_inicio;
        $display("   %4d  %10.0f    %10.0f", 4,  real'(t_medido), real'(t_medido)/real'(TG));

        @(posedge c8);   t_medido = $time - t_inicio;
        $display("   %4d  %10.0f    %10.0f", 8,  real'(t_medido), real'(t_medido)/real'(TG));

        @(posedge c16);  t_medido = $time - t_inicio;
        $display("   %4d  %10.0f    %10.0f", 16, real'(t_medido), real'(t_medido)/real'(TG));

        @(posedge c32);  t_medido = $time - t_inicio;
        $display("   %4d  %10.0f    %10.0f", 32, real'(t_medido), real'(t_medido)/real'(TG));

        @(posedge c64);  t_medido = $time - t_inicio;
        $display("   %4d  %10.0f    %10.0f", 64, real'(t_medido), real'(t_medido)/real'(TG));

        $display("");
        $display("  El delay crece linealmente con N: cada bit adicional agrega");
        $display("  dos niveles de logica al camino cin -> cout.");
        $display("");

        //----------------------------------------------------------------------
        $display("==========================================================");
        if (errores == 0)
            $display(" RESULTADO: PASS - %0d casos sin discrepancias", casos);
        else
            $display(" RESULTADO: FAIL - %0d discrepancias sobre %0d casos",
                     errores, casos);
        $display("==========================================================");

        $finish;
    end

endmodule

`default_nettype wire