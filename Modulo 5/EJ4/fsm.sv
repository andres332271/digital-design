`timescale 1ns/1ps

module fsm #(
    parameter int N_ITER = 4
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    output logic en,
    output logic sel,
    output logic done
);

  localparam int COUNT_W = (N_ITER <= 1) ? 1 : $clog2(N_ITER);

  typedef enum logic [1:0] {
    IDLE,
    INIT,
    ITER,
    DONE
  } state_t;

  state_t state, next_state;
  logic [COUNT_W-1:0] cont;

  // Registros de estado y del contador de iteraciones.
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
      cont  <= '0;
    end else begin
      state <= next_state;

      if (state == INIT) begin
        cont <= '0;
      end else if ((state == ITER) && (cont < N_ITER - 1)) begin
        cont <= cont + 1'b1;
      end
    end
  end

  // Logica de proximo estado y salidas de control.
  always_comb begin
    next_state = state;
    en         = 1'b0;
    sel        = 1'b0;
    done       = 1'b0;

    case (state)
      IDLE: begin
        if (start) begin
          next_state = INIT;
        end
      end

      INIT: begin
        // Carga la semilla y0 desde la LUT en el registro y.
        en         = 1'b1;
        sel        = 1'b0;
        next_state = ITER;
      end

      ITER: begin
        // Selecciona el feedback y registra una iteracion de NR.
        en  = 1'b1;
        sel = 1'b1;

        if (cont == N_ITER - 1) begin
          next_state = DONE;
        end
      end

      DONE: begin
        done       = 1'b1;
        next_state = IDLE;
      end

      default: begin
        next_state = IDLE;
      end
    endcase
  end

endmodule
