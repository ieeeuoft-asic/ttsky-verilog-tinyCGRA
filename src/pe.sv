module pe #(
    parameter int DATA_WIDTH = 8,
    parameter int CONTEXTS   = 1
) (
    input  logic                  clk_i,
    input  logic                  rst_n_i,
    input  logic                  en_i,
    input  logic                  config_di_i,
    input  logic                  config_shift_en_i,
    input  logic [((CONTEXTS <= 1) ? 1 : $clog2(CONTEXTS))-1:0] context_id_i,
    output logic                  config_do_o,
    input  logic [DATA_WIDTH-1:0] north_i,
    input  logic [DATA_WIDTH-1:0] south_i,
    input  logic [DATA_WIDTH-1:0] east_i,
    input  logic [DATA_WIDTH-1:0] west_i,
    output logic [DATA_WIDTH-1:0] data_o
);
    localparam int CONFIG_WIDTH = 6;
    localparam int CONTEXT_ID_WIDTH = (CONTEXTS <= 1) ? 1 : $clog2(CONTEXTS);

    logic [CONFIG_WIDTH-1:0] config_reg [0:CONTEXTS-1];
    logic [CONFIG_WIDTH-1:0] active_config;

    logic [DATA_WIDTH-1:0] X;
    logic [DATA_WIDTH-1:0] Y;
    logic [DATA_WIDTH-1:0] R;

    always_comb begin
        active_config = config_reg[0];
        for (int ctx_idx = 1; ctx_idx < CONTEXTS; ctx_idx++) begin
            if (context_id_i == ctx_idx[CONTEXT_ID_WIDTH-1:0]) begin
                active_config = config_reg[ctx_idx];
            end
        end
    end

    always_comb begin
        X = '0;
        Y = '0;

        unique case (active_config[5:4])
            2'b00: X = north_i;
            2'b01: X = south_i;
            2'b10: X = east_i;
            2'b11: X = west_i;
            default: X = '0;
        endcase

        unique case (active_config[3:2])
            2'b00: Y = north_i;
            2'b01: Y = south_i;
            2'b10: Y = east_i;
            2'b11: Y = west_i;
            default: Y = '0;
        endcase
    end

    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu (
        .op_i(active_config[1:0]),
        .X(X),
        .Y(Y),
        .R(R)
    );

    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            for (int ctx_idx = 0; ctx_idx < CONTEXTS; ctx_idx++) begin
                config_reg[ctx_idx] <= '0;
            end
            data_o <= '0;
        end else begin
            if (config_shift_en_i) begin
                config_reg[0] <= {config_di_i, config_reg[0][CONFIG_WIDTH-1:1]};
                for (int ctx_idx = 1; ctx_idx < CONTEXTS; ctx_idx++) begin
                    config_reg[ctx_idx] <= {config_reg[ctx_idx-1][0], config_reg[ctx_idx][CONFIG_WIDTH-1:1]};
                end
            end else if (en_i) begin
                data_o <= R;
            end
        end
    end

    assign config_do_o = config_reg[CONTEXTS-1][0];
endmodule
