module cgra_3x3_top #(
    parameter int DATA_WIDTH = 8,
    parameter int CONTEXTS = 1,
    parameter CONNECT_TYPE = "NSWE"
) (
    input  logic                    clk_i,
    input  logic                    rst_n_i,
    input  logic                    en_i,
    input  logic                    config_di_i,
    input  logic                    config_shift_en_i,
    input  logic [((CONTEXTS <= 1) ? 1 : $clog2(CONTEXTS))-1:0] context_id_i,
    output logic                    config_do_o,
    input  logic [3*DATA_WIDTH-1:0] north_bus_i,
    input  logic [3*DATA_WIDTH-1:0] south_bus_i,
    input  logic [3*DATA_WIDTH-1:0] east_bus_i,
    input  logic [3*DATA_WIDTH-1:0] west_bus_i,
    output logic [9*DATA_WIDTH-1:0] pe_data_o
);
    // Area-study top for a 3x3 array of 9 PEs.
    pe_array_mesh #(
        .DATA_WIDTH(DATA_WIDTH),
        .ROWS(3),
        .COLS(3),
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
        .east_bus_i(east_bus_i),
        .west_bus_i(west_bus_i),
        .pe_data_o(pe_data_o)
    );
endmodule
