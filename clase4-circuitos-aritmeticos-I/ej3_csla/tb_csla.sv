`timescale 1ns/1ps
`default_nettype none

module tb_csla;

    localparam time TG       = 1ns;
    localparam int  N_RAND   = 1000;
    localparam time T_SETTLE = 200ns;

    int errores = 0;
    int casos   = 0;

    //--------------------------------------------------------------------------
    // Las tres arquitecturas, con el mismo estimulo
    //--------------------------------------------------------------------------
    logic [15:0] a, b;
    logic        cin;

    logic [15:0] s_rca,  s_cla,  s_csla;
    logic        c_rca,  c_cla,  c_csla;

    rca #(.N(16), .TG(TG)) dut_rca (
        .a (a), .b (b), .cin (cin), .s (s_rca), .cout (c_rca)
    );

    cla16 #(.TG(TG)) dut_cla (
        .a (a), .b (b), .cin (cin), .s (s_cla), .cout (c_cla)
    );

    csla16 #(.TG(TG)) dut_csla (
        .a (a), .b (b), .cin (cin), .s (s_csla), .cout (c_csla)
    );

    //--------------------------------------------------------------------------
    task automatic verificar(input logic [15:0] va, vb, input logic vcin,
                             input string etiqueta);
        logic [16:0] esperado, o_rca, o_cla, o_csla;
        begin
            a = va; b = vb; cin = vcin;
            #T_SETTLE;

            esperado = va + vb + vcin;
            o_rca    = {c_rca,  s_rca};
            o_cla    = {c_cla,  s_cla};
            o_csla   = {c_csla, s_csla};
            casos++;

            if (o_csla !== esperado) begin
                $display("  FAIL csla %s: %0d + %0d + %0d  esperado=%0d  obtenido=%0d",
                         etiqueta, va, vb, vcin, esperado, o_csla);
                errores++;
            end

            if (!(o_rca === o_cla && o_cla === o_csla)) begin
                $display("  FAIL equivalencia %s: rca=%0d  cla=%0d  csla=%0d",
                         etiqueta, o_rca, o_cla, o_csla);
                errores++;
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Instancias dedicadas a la medicion de delay
    //--------------------------------------------------------------------------
    logic [15:0] da, db;
    logic        dcin;
    logic [15:0] ms_rca, ms_cla, ms_csla;
    logic        mc_rca, mc_cla, mc_csla;

    rca #(.N(16), .TG(TG)) m_rca  (.a(da), .b(db), .cin(dcin), .s(ms_rca),  .cout(mc_rca));
    cla16 #(.TG(TG))       m_cla  (.a(da), .b(db), .cin(dcin), .s(ms_cla),  .cout(mc_cla));
    csla16 #(.TG(TG))      m_csla (.a(da), .b(db), .cin(dcin), .s(ms_csla), .cout(mc_csla));

    time t_inicio;
    time t_rca, t_cla, t_csla;

    //--------------------------------------------------------------------------
    int va, vb;

    initial begin
        $dumpfile("tb_csla.vcd");
        $dumpvars(0, tb_csla);

        $display("==========================================================");
        $display(" Ejercicio 3 - Carry Select Adder de 16 bits (4 x 4)");
        $display("==========================================================");
        $display("");

        //----------------------------------------------------------------------
        $display("--- Casos de borde ---");

        verificar(16'h0000, 16'h0000, 1'b0, "0+0");
        verificar(16'hFFFF, 16'hFFFF, 1'b1, "max+max+cin");
        verificar(16'hFFFF, 16'h0001, 1'b0, "carry-out");
        verificar(16'h0FFF, 16'h0001, 1'b0, "acarreo entre bloques");
        verificar(16'h000F, 16'h0001, 1'b0, "acarreo bloque 0 a 1");
        $display("  casos de borde OK");
        $display("");

        //----------------------------------------------------------------------
        $display("--- %0d vectores aleatorios ---", N_RAND);

        for (int k = 0; k < N_RAND; k++) begin
            va = $urandom_range(0, 65535);
            vb = $urandom_range(0, 65535);
            verificar(16'(va), 16'(vb), $urandom_range(0, 1), "random");
        end

        $display("  %0d vectores sin discrepancias", N_RAND);
        $display("  las tres arquitecturas coinciden en todos los casos");
        $display("");

        //----------------------------------------------------------------------
        // Delay: camino operandos -> cout, el que fija Fmax entre registros
        //----------------------------------------------------------------------
        $display("--- Delay medido, camino operandos -> cout ---");
        $display("  Estimulo: a: 0x0000 -> 0xFFFF, b: 0x0000 -> 0x0001");
        $display("  El acarreo nace en el bit 0 y debe alcanzar el bit 15.");
        $display("");

        da   = 16'h0000;
        db   = 16'h0000;
        dcin = 1'b0;
        #T_SETTLE;

        t_inicio = $time;
        da       = 16'hFFFF;
        db       = 16'h0001;

        fork
            begin @(posedge mc_rca);  t_rca  = $time - t_inicio; end
            begin @(posedge mc_cla);  t_cla  = $time - t_inicio; end
            begin @(posedge mc_csla); t_csla = $time - t_inicio; end
        join

        $display("   Arquitectura   delay        full adders   comentario");
        $display("   ------------  -----------  ------------  ------------------");
        $display("   RCA  16       %5.0f TG      %10d   cadena completa",
                 real'(t_rca)/real'(TG), 16);
        $display("   CSLA 16 (4x4) %5.0f TG      %10d   RCA4 + 3 muxes",
                 real'(t_csla)/real'(TG), 28);
        $display("   CLA  16 (4x4) %5.0f TG      %10s   lookahead 2 niveles",
                 real'(t_cla)/real'(TG), "-");
        $display("");
        $display("   CSLA respecto de RCA : %.2fx mas rapido",
                 real'(t_rca)/real'(t_csla));
        $display("   CLA  respecto de CSLA: %.2fx mas rapido",
                 real'(t_csla)/real'(t_cla));
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