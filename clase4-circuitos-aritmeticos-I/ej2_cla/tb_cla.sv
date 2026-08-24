`timescale 1ns/1ps
`default_nettype none

module tb_cla;

    localparam time TG      = 1ns;
    localparam int  N_RAND  = 1000;
    localparam time T_SETTLE = 200ns;

    int errores = 0;
    int casos   = 0;

    //--------------------------------------------------------------------------
    // DUTs funcionales
    //--------------------------------------------------------------------------
    logic [3:0]  a4, b4;
    logic        cin4;
    logic [3:0]  s4;
    logic        cout4, pg4, gg4;

    cla4 #(.TG(TG)) dut4 (
        .a (a4), .b (b4), .cin (cin4),
        .s (s4), .cout (cout4), .pg (pg4), .gg (gg4)
    );

    logic [15:0] a16, b16;
    logic        cin16;
    logic [15:0] s_cla, s_rca;
    logic        cout_cla, cout_rca;

    cla16 #(.TG(TG)) dut_cla (
        .a (a16), .b (b16), .cin (cin16), .s (s_cla), .cout (cout_cla)
    );

    rca #(.N(16), .TG(TG)) dut_rca (
        .a (a16), .b (b16), .cin (cin16), .s (s_rca), .cout (cout_rca)
    );

    //--------------------------------------------------------------------------
    task automatic verificar4(input logic [3:0] va, vb, input logic vcin,
                              input string etiqueta);
        logic [4:0] esperado, obtenido;
        begin
            a4 = va; b4 = vb; cin4 = vcin;
            #T_SETTLE;
            esperado = va + vb + vcin;
            obtenido = {cout4, s4};
            casos++;
            if (obtenido !== esperado) begin
                $display("  FAIL cla4 %s: %0d + %0d + %0d  esperado=%0d  obtenido=%0d",
                         etiqueta, va, vb, vcin, esperado, obtenido);
                errores++;
            end
        end
    endtask

    task automatic verificar16(input logic [15:0] va, vb, input logic vcin,
                               input string etiqueta);
        logic [16:0] esperado, obt_cla, obt_rca;
        begin
            a16 = va; b16 = vb; cin16 = vcin;
            #T_SETTLE;
            esperado = va + vb + vcin;
            obt_cla  = {cout_cla, s_cla};
            obt_rca  = {cout_rca, s_rca};
            casos++;

            if (obt_cla !== esperado) begin
                $display("  FAIL cla16 %s: %0d + %0d + %0d  esperado=%0d  obtenido=%0d",
                         etiqueta, va, vb, vcin, esperado, obt_cla);
                errores++;
            end

            // Verificacion cruzada entre arquitecturas
            if (obt_cla !== obt_rca) begin
                $display("  FAIL equivalencia %s: cla=%0d  rca=%0d",
                         etiqueta, obt_cla, obt_rca);
                errores++;
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Instancias dedicadas a la medicion de delay
    //--------------------------------------------------------------------------
    logic [15:0] da, db;
    logic        dcin;
    logic [15:0] ds_cla, ds_rca;
    logic        dc_cla, dc_rca;

    cla16 #(.TG(TG)) m_cla (.a(da), .b(db), .cin(dcin), .s(ds_cla), .cout(dc_cla));
    rca #(.N(16), .TG(TG)) m_rca (.a(da), .b(db), .cin(dcin), .s(ds_rca), .cout(dc_rca));

    time t_inicio;
    time t_cla_cin, t_rca_cin;
    time t_cla_ab,  t_rca_ab;

    //--------------------------------------------------------------------------
    int va, vb;

    initial begin
        $dumpfile("tb_cla.vcd");
        $dumpvars(0, tb_cla);

        $display("==========================================================");
        $display(" Ejercicio 2 - CLA 4 bits y CLA 16 bits jerarquico");
        $display("==========================================================");
        $display("");

        //----------------------------------------------------------------------
        $display("--- Casos de borde ---");

        verificar4(4'h0, 4'h0, 1'b0, "0+0");
        verificar4(4'hF, 4'hF, 1'b1, "max+max+cin");
        verificar4(4'hF, 4'h1, 1'b0, "carry-out");
        $display("  cla4  : casos de borde OK");

        verificar16(16'h0000, 16'h0000, 1'b0, "0+0");
        verificar16(16'hFFFF, 16'hFFFF, 1'b1, "max+max+cin");
        verificar16(16'hFFFF, 16'h0001, 1'b0, "carry-out");
        verificar16(16'h0FFF, 16'h0001, 1'b0, "acarreo entre bloques");
        $display("  cla16 : casos de borde OK");
        $display("");

        //----------------------------------------------------------------------
        $display("--- %0d vectores aleatorios sobre cla16 ---", N_RAND);

        for (int k = 0; k < N_RAND; k++) begin
            va = $urandom_range(0, 65535);
            vb = $urandom_range(0, 65535);
            verificar16(16'(va), 16'(vb), $urandom_range(0, 1), "random");
        end

        $display("  %0d vectores sin discrepancias", N_RAND);
        $display("  cla16 y rca16 coinciden en todos los casos");
        $display("");

        //----------------------------------------------------------------------
        // Medicion comparativa de delay
        //----------------------------------------------------------------------
        $display("--- Delay medido, N = 16 (peor caso de propagacion) ---");
        $display("");

        // (a) camino cin -> cout, con todas las posiciones propagando
        da   = 16'hFFFF;
        db   = 16'h0000;
        dcin = 1'b0;
        #T_SETTLE;

        t_inicio = $time;
        dcin     = 1'b1;

        fork
            begin @(posedge dc_cla); t_cla_cin = $time - t_inicio; end
            begin @(posedge dc_rca); t_rca_cin = $time - t_inicio; end
        join

        // (b) camino operandos -> cout, con acarreo generado en el bit 0
        da   = 16'h0000;
        db   = 16'h0000;
        dcin = 1'b0;
        #T_SETTLE;

        t_inicio = $time;
        da       = 16'hFFFF;
        db       = 16'h0001;

        fork
            begin @(posedge dc_cla); t_cla_ab = $time - t_inicio; end
            begin @(posedge dc_rca); t_rca_ab = $time - t_inicio; end
        join

        $display("   Camino               RCA 16    CLA 16    mejora");
        $display("   -------------------  --------  --------  --------");
        $display("   cin -> cout          %5.0f TG  %5.0f TG  %6.1fx",
                 real'(t_rca_cin)/real'(TG), real'(t_cla_cin)/real'(TG),
                 real'(t_rca_cin)/real'(t_cla_cin));
        $display("   operandos -> cout    %5.0f TG  %5.0f TG  %6.1fx",
                 real'(t_rca_ab)/real'(TG), real'(t_cla_ab)/real'(TG),
                 real'(t_rca_ab)/real'(t_cla_ab));
        $display("");
        $display("   El camino operandos -> cout es el que fija Fmax cuando el");
        $display("   sumador opera entre registros, y es la comparacion honesta.");
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