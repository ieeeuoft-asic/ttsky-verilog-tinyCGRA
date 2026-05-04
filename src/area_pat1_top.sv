module area_pat1_top (
    input  logic         clk_i,
    input  logic         rst_n_i,
    input  logic         en_i,
    input  logic         config_di_i,
    input  logic         config_shift_en_i,
    input  logic         context_id_i,
    output logic         config_do_o,
    input  logic [23:0]  north_bus_i,
    input  logic [23:0]  south_bus_i,
    input  logic [23:0]  east_bus_i,
    input  logic [23:0]  west_bus_i,
    output logic [71:0]  pe_data_o
);
    area_bench_top #(
        .PATTERN(1)
    ) u_dut (
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
