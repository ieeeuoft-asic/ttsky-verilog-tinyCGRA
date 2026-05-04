module pe_multi #(
    parameter int DATA_WIDTH = 8,
    parameter int CONTEXTS   = 4
) (
    input  logic                  clk_i,
    input  logic                  rst_n_i,
    input  logic                  en_i,

    input  logic                  config_di_i,
    input  logic                  config_shift_en_i,
    output logic                  config_do_o,

    input  logic [DATA_WIDTH-1:0] north_i,
    input  logic [DATA_WIDTH-1:0] south_i,
    input  logic [DATA_WIDTH-1:0] east_i,
    input  logic [DATA_WIDTH-1:0] west_i,
    output logic [DATA_WIDTH-1:0] data_o
);
    typedef struct packed {
        logic [1:0] sel_a;
        logic [1:0] sel_b;
        logic [1:0] op;
    } config_t;

    localparam int CONFIG_WIDTH  = $bits(config_t);
    localparam int CONTEXT_IDX_W = (CONTEXTS <= 1) ? 1 : $clog2(CONTEXTS);

    config_t config_reg [CONTEXTS];
    logic [CONTEXT_IDX_W-1:0] context_idx;
    config_t active_cfg;

    logic [DATA_WIDTH-1:0] X, Y, R;

    assign active_cfg = config_reg[context_idx];

    always_comb begin
        X = '0;
        Y = '0;

        unique case (active_cfg.sel_a)
            2'b00: X = north_i;
            2'b01: X = south_i;
            2'b10: X = east_i;
            2'b11: X = west_i;
            default: X = '0;
        endcase

        unique case (active_cfg.sel_b)
            2'b00: Y = north_i;
            2'b01: Y = south_i;
            2'b10: Y = east_i;
            2'b11: Y = west_i;
            default: Y = '0;
        endcase
    end

    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu(
        .op_i(active_cfg.op),
        .X(X),
        .Y(Y),
        .R(R)
    );

    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            for (int i = 0; i < CONTEXTS; i++) begin
                config_reg[i] <= '0;
            end
            context_idx <= '0;
            data_o      <= '0;
        end else begin
            if (config_shift_en_i) begin
                for (int i = 0; i < CONTEXTS; i++) begin
                    if (i == 0)
                        config_reg[i] <= {config_di_i, config_reg[i][CONFIG_WIDTH-1:1]};
                    else
                        config_reg[i] <= {config_reg[i-1][0], config_reg[i][CONFIG_WIDTH-1:1]};
                end
            end else if (en_i) begin
                data_o      <= R;
                context_idx <= context_idx + 1'b1;
            end
        end
    end

    assign config_do_o = config_reg[CONTEXTS-1][0];

endmodule