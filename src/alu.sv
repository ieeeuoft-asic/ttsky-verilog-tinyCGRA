module alu #(
    parameter int DATA_WIDTH = 8
)(
    input logic [1:0] op_i,
    input logic [DATA_WIDTH-1:0] X,
    input logic [DATA_WIDTH-1:0] Y,
    output logic [DATA_WIDTH-1:0] R
);
    always_comb begin
        case (op_i)
            2'b00: R = X + Y;
            2'b01: R = X - Y;
            2'b10: R = X * Y;
            default: R = '0;
        endcase
    end
endmodule
