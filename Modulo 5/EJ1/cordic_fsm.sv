// Control del CORDIC folded. No contiene operaciones aritmeticas.
module cordic_fsm (
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic iter_last,
    output logic load,
    output logic iter_en,
    output logic result_en,
    output logic busy,
    output logic done
);
    typedef enum logic [1:0] {IDLE, ITER, DONE} state_t;
    state_t state, next_state;

    always_ff @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always_comb begin
        load      = 1'b0;
        iter_en   = 1'b0;
        result_en = 1'b0;
        busy      = 1'b0;
        done      = 1'b0;
        next_state = state;

        case (state)
            IDLE: if (start) begin
                load       = 1'b1;
                next_state = ITER;
            end
            ITER: begin
                iter_en = 1'b1;
                busy    = 1'b1;
                if (iter_last) begin
                    result_en = 1'b1;
                    next_state = DONE;
                end
            end
            DONE: begin
                done       = 1'b1;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule
