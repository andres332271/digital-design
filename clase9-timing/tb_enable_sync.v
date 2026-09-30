`timescale 1ns/1ps

// Testbench provisto para practicar. No hace falta modificarlo para resolver
// el ejercicio: completa enable_sync.v y ejecuta ./run.sh.
module tb_enable_sync;
    localparam WIDTH = 8;
    localparam NUM_CASOS = 200;

    reg clkA = 1'b0;
    reg clkB = 1'b0;
    reg rst_n = 1'b0;
    reg [WIDTH-1:0] data_in = {WIDTH{1'b0}};
    reg valid_in = 1'b0;
    wire [WIDTH-1:0] data_out;
    wire data_valid;

    reg [WIDTH-1:0] esperado [0:NUM_CASOS-1];
    reg data_valid_anterior = 1'b0;
    integer enviados = 0;
    integer recibidos = 0;
    integer i;

    // 125 MHz: periodo de 8 ns.
    always #4 clkA = ~clkA;
    // Aproximadamente 38 MHz: periodo de 26.316 ns.
    always #13.158 clkB = ~clkB;

    enable_sync #(.WIDTH(WIDTH)) dut (
        .clkA(clkA),
        .clkB(clkB),
        .rst_n(rst_n),
        .data_in(data_in),
        .valid_in(valid_in),
        .data_out(data_out),
        .data_valid(data_valid)
    );

    function [WIDTH-1:0] dato_prueba;
        input integer indice;
        begin
            case (indice)
                0: dato_prueba = 8'h00;
                1: dato_prueba = 8'hFF;
                2: dato_prueba = 8'h55;
                3: dato_prueba = 8'hAA;
                default: dato_prueba = (indice * 73) ^ (indice >> 1);
            endcase
        end
    endfunction

    // Se observa despues de que actualicen los registros del receptor.
    always @(posedge clkB) begin
        if (!rst_n) begin
            data_valid_anterior = 1'b0;
        end else begin
            #1;
            if (data_valid !== 1'b0 && data_valid !== 1'b1)
                $fatal(1, "FAIL: data_valid tiene valor X o Z");

            if (data_valid) begin
                if (data_valid_anterior)
                    $fatal(1, "FAIL: data_valid duro mas de un ciclo clkB");
                if (recibidos >= enviados)
                    $fatal(1, "FAIL: dato recibido sin transferencia pendiente");
                if (data_out !== esperado[recibidos])
                    $fatal(1, "FAIL caso %0d: esperado %02h, recibido %02h",
                           recibidos, esperado[recibidos], data_out);
                recibidos = recibidos + 1;
            end
            data_valid_anterior = data_valid;
        end
    end

    initial begin
        repeat (4) @(negedge clkA);
        rst_n = 1'b1;
        repeat (3) @(posedge clkB);

        for (i = 0; i < NUM_CASOS; i = i + 1) begin
            @(negedge clkA);
            esperado[i] = dato_prueba(i);
            data_in = esperado[i];
            valid_in = 1'b1;
            enviados = i + 1;

            // El dato y valid se mantienen hasta que clkB pueda verlos.
            repeat (6) @(posedge clkB);
            @(negedge clkA);
            valid_in = 1'b0;
            // Dejar que el cero atraviese los dos FF antes del proximo caso.
            repeat (4) @(posedge clkB);

            if (recibidos != i + 1)
                $fatal(1, "FAIL caso %0d: no se recibio exactamente un dato", i);
        end

        $display("PASS %0d/%0d", recibidos, NUM_CASOS);
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "FAIL: timeout");
    end
endmodule
