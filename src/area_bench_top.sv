module area_bench_top #(
    parameter int DATA_WIDTH = 8,
    parameter int PATTERN = 0
) (
    input  logic                                                       clk_i,
    input  logic                                                       rst_n_i,
    input  logic                                                       en_i,
    input  logic                                                       config_di_i,
    input  logic                                                       config_shift_en_i,
    input  logic                                                       context_id_i,
    output logic                                                       config_do_o,
    input  logic [(((PATTERN == 0) ? 2 : 3) * DATA_WIDTH)-1:0]         north_bus_i,
    input  logic [(((PATTERN == 0) ? 2 : 3) * DATA_WIDTH)-1:0]         south_bus_i,
    input  logic [(((PATTERN == 0) ? 2 : 3) * DATA_WIDTH)-1:0]         east_bus_i,
    input  logic [(((PATTERN == 0) ? 2 : 3) * DATA_WIDTH)-1:0]         west_bus_i,
    output logic [((((PATTERN == 0) ? 2 : 3) * ((PATTERN == 0) ? 2 : 3) * DATA_WIDTH))-1:0] pe_data_o
);
    localparam int ROWS = (PATTERN == 0) ? 2 : 3;
    localparam int COLS = (PATTERN == 0) ? 2 : 3;
    localparam int CONTEXTS = (PATTERN == 2) ? 1 : 2;
    localparam int CONTEXT_ID_WIDTH = (CONTEXTS <= 1) ? 1 : $clog2(CONTEXTS);
    localparam CONNECT_TYPE = (PATTERN == 1) ? "NS" : "NSWE";

    pe_array_mesh #(
        .DATA_WIDTH(DATA_WIDTH),
        .ROWS(ROWS),
        .COLS(COLS),
        .CONTEXTS(CONTEXTS),
        .CONNECT_TYPE(CONNECT_TYPE)
    ) u_array (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),
        .config_di_i(config_di_i),
        .config_shift_en_i(config_shift_en_i),
        .context_id_i(context_id_i),
        .config_do_o(config_do_o),
        .north_bus_i(north_bus_i),
        .south_bus_i(south_bus_i),
        .east_bus_i(east_bus_i[ROWS*DATA_WIDTH-1:0]),
        .west_bus_i(west_bus_i[ROWS*DATA_WIDTH-1:0]),
        .pe_data_o(pe_data_o)
    );
endmodule
