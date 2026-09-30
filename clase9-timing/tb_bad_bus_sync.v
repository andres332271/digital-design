`timescale 1ns/1ps

// Demostracion determinista de un bus que llega con skew entre bits.
// No modela metaestabilidad: solo muestra una palabra intermedia posible.
module tb_bad_bus_sync;
    reg clkB = 1'b0;
    reg rst_n = 1'b0;
    reg [7:0] data_async = 8'h00;
    wire [7:0] data_out;

    always #10 clkB = ~clkB;

    bad_bus_sync #(.WIDTH(8)) dut (
        .clkB(clkB),
        .rst_n(rst_n),
        .data_async(data_async),
        .data_out(data_out)
    );

    initial begin
        #2 rst_n = 1'b1;

        // Los bits del nuevo dato 0xFF llegan entre 21 y 35 ns.
        // En el flanco de 30 ns el receptor ve 0x1F.
        fork
            begin #19 data_async[0] = 1'b1; end
            begin #21 data_async[1] = 1'b1; end
            begin #23 data_async[2] = 1'b1; end
            begin #25 data_async[3] = 1'b1; end
            begin #27 data_async[4] = 1'b1; end
            begin #29 data_async[5] = 1'b1; end
            begin #31 data_async[6] = 1'b1; end
            begin #33 data_async[7] = 1'b1; end
        join

        #16; // 51 ns: segunda etapa ya capturo el valor visto a los 30 ns.
        if (data_out !== 8'h1F)
            $fatal(1, "FAIL demo: se esperaba 0x1F, se obtuvo 0x%02h", data_out);
        $display("PASS demo: bad_bus_sync entrego 0x%02h entre 0x00 y 0xFF", data_out);

        #20; // 71 ns: llega finalmente 0xFF.
        if (data_out !== 8'hFF)
            $fatal(1, "FAIL demo: se esperaba 0xFF, se obtuvo 0x%02h", data_out);
        $finish;
    end
endmodule
