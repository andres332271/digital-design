
module test_alu (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [7:0] a,
    output reg  [7:0] b,
    output reg  [1:0] op
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a  <= 8'd8;
      b  <= 8'd15;
      op <= 2'd0;
    end else begin
      op <= op + 2'd1;
    end
  end

endmodule
