module pe_array_mesh #(
    parameter int DATA_WIDTH = 8,
    parameter int ROWS = 2,
    parameter int COLS = 2,
    parameter int CONTEXTS = 1,
    parameter CONNECT_TYPE = "NSWE"
) (
    input  logic                             clk_i,
    input  logic                             rst_n_i,
    input  logic                             en_i,
    input  logic                             config_di_i,
    input  logic                             config_shift_en_i,
    input  logic [((CONTEXTS <= 1) ? 1 : $clog2(CONTEXTS))-1:0] context_id_i,
    output logic                             config_do_o,
    input  logic [COLS*DATA_WIDTH-1:0]       north_bus_i,
    input  logic [COLS*DATA_WIDTH-1:0]       south_bus_i,
    input  logic [ROWS*DATA_WIDTH-1:0]       east_bus_i,
    input  logic [ROWS*DATA_WIDTH-1:0]       west_bus_i,
    output logic [ROWS*COLS*DATA_WIDTH-1:0]  pe_data_o
);
    localparam int NUM_PES = ROWS * COLS;
    localparam bit CONNECT_NS = (CONNECT_TYPE == "NS");

    logic [DATA_WIDTH-1:0] pe_out [0:ROWS-1][0:COLS-1];
    logic [NUM_PES-1:0] config_chain;

    genvar row;
    genvar col;
    generate
        for (row = 0; row < ROWS; row++) begin : gen_row
            for (col = 0; col < COLS; col++) begin : gen_col
                localparam int PE_INDEX = (row * COLS) + col;
                logic [DATA_WIDTH-1:0] north_sig;
                logic [DATA_WIDTH-1:0] south_sig;
                logic [DATA_WIDTH-1:0] east_sig;
                logic [DATA_WIDTH-1:0] west_sig;

                if (row == 0) begin : gen_north_edge
                    assign north_sig = north_bus_i[(col*DATA_WIDTH) +: DATA_WIDTH];
                end else begin : gen_north_internal
                    assign north_sig = pe_out[row-1][col];
                end

                if (row == ROWS-1) begin : gen_south_edge
                    assign south_sig = south_bus_i[(col*DATA_WIDTH) +: DATA_WIDTH];
                end else begin : gen_south_internal
                    assign south_sig = pe_out[row+1][col];
                end

                if (col == COLS-1) begin : gen_east_edge
                    if (CONNECT_NS) begin : gen_east_disabled
                        assign east_sig = '0;
                    end else begin : gen_east_enabled
                        assign east_sig = east_bus_i[(row*DATA_WIDTH) +: DATA_WIDTH];
                    end
                end else begin : gen_east_internal
                    if (CONNECT_NS) begin : gen_east_internal_disabled
                        assign east_sig = '0;
                    end else begin : gen_east_internal_enabled
                        assign east_sig = pe_out[row][col+1];
                    end
                end

                if (col == 0) begin : gen_west_edge
                    if (CONNECT_NS) begin : gen_west_disabled
                        assign west_sig = '0;
                    end else begin : gen_west_enabled
                        assign west_sig = west_bus_i[(row*DATA_WIDTH) +: DATA_WIDTH];
                    end
                end else begin : gen_west_internal
                    if (CONNECT_NS) begin : gen_west_internal_disabled
                        assign west_sig = '0;
                    end else begin : gen_west_internal_enabled
                        assign west_sig = pe_out[row][col-1];
                    end
                end

                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .CONTEXTS(CONTEXTS)
                ) u_pe (
                    .clk_i(clk_i),
                    .rst_n_i(rst_n_i),
                    .en_i(en_i),
                    .config_di_i((PE_INDEX == 0) ? config_di_i : config_chain[PE_INDEX-1]),
                    .config_shift_en_i(config_shift_en_i),
                    .context_id_i(context_id_i),
                    .config_do_o(config_chain[PE_INDEX]),
                    .north_i(north_sig),
                    .south_i(south_sig),
                    .east_i(east_sig),
                    .west_i(west_sig),
                    .data_o(pe_out[row][col])
                );

                assign pe_data_o[(PE_INDEX*DATA_WIDTH) +: DATA_WIDTH] = pe_out[row][col];
            end
        end
    endgenerate

    assign config_do_o = config_chain[NUM_PES-1];
endmodule
