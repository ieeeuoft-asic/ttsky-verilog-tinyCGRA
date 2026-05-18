`default_nettype none

module tt_um_tinycgra (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  localparam int         PE_CONFIG_BITS    = 6;
  localparam int         NUM_PES           = 4;
  localparam logic [4:0] TOTAL_CONFIG_BITS = 5'd24;
  localparam int         ROWS              = 2;
  localparam int         COLS              = 2;

  logic [COLS*8-1:0] north_bus;
  logic [COLS*8-1:0] south_bus;
  logic [ROWS*8-1:0] east_bus;
  logic [ROWS*8-1:0] west_bus;
  logic [7:0] pe_data_00;
  logic [7:0] pe_data_01;
  logic [7:0] pe_data_10;
  logic [7:0] pe_data_11;
  logic [7:0] input_reg;
  logic [7:0] selected_data;
  logic       config_mode;
  logic       config_di;
  logic       config_shift_en;
  logic       run_en;
  logic       load_input;
  logic       debug_xor_mode;
  logic       config_do;
  logic       config_done;
  logic [4:0] config_count;
  logic [0:0] context_id;

  assign context_id = '0;

  assign config_mode     = uio_in[5];
  assign config_di       = uio_in[0];
  assign config_shift_en = config_mode & uio_in[1];
  assign run_en          = ~config_mode & uio_in[2];
  assign load_input      = ~config_mode & uio_in[6];
  assign debug_xor_mode  = ~config_mode & uio_in[7];
  assign config_done     = (config_count == TOTAL_CONFIG_BITS);

  // Separate the external input pins from the array boundary by latching ui_in.
  assign north_bus = {input_reg, input_reg};
  assign west_bus  = {input_reg, input_reg};
  assign south_bus = '0;
  assign east_bus  = '0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      input_reg <= '0;
    end else if (load_input) begin
      input_reg <= ui_in;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      config_count <= '0;
    end else if (!config_mode) begin
      config_count <= '0;
    end else if (config_shift_en && !config_done) begin
      config_count <= config_count + 5'd1;
    end
  end

  always_comb begin
    if (debug_xor_mode) begin
      selected_data = pe_data_00 ^ pe_data_01 ^ pe_data_10 ^ pe_data_11;
    end else begin
      unique case (uio_in[4:3])
        2'b00: selected_data = pe_data_00;
        2'b01: selected_data = pe_data_01;
        2'b10: selected_data = pe_data_10;
        2'b11: selected_data = pe_data_11;
        default: selected_data = '0;
      endcase
    end
  end

  logic [31:0] pe_data_o_bus;

  pe_array_mesh #(
      .DATA_WIDTH(8),
      .ROWS(ROWS),
      .COLS(COLS)
  ) u_array (
      .clk_i(clk),
      .rst_n_i(rst_n),
      .en_i(run_en),
      .config_di_i(config_di),
      .config_shift_en_i(config_shift_en),
      .context_id_i(context_id),
      .config_do_o(config_do),
      .north_bus_i(north_bus),
      .south_bus_i(south_bus),
      .east_bus_i(east_bus),
      .west_bus_i(west_bus),
      .pe_data_o(pe_data_o_bus)
  );

  assign pe_data_00 = pe_data_o_bus[0*8 +: 8];
  assign pe_data_01 = pe_data_o_bus[1*8 +: 8];
  assign pe_data_10 = pe_data_o_bus[2*8 +: 8];
  assign pe_data_11 = pe_data_o_bus[3*8 +: 8];


  assign uo_out = selected_data;
  assign uio_out = {6'b0, config_done, config_do};
  assign uio_oe = config_mode ? 8'b0000_0000 : 8'b0000_0011;

  wire _unused = &{ena, 1'b0};

endmodule
