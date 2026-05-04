`default_nettype none
`timescale 1ns / 1ps

module tb_area ();

  initial begin
    $dumpfile("tb_area.fst");
    $dumpvars(0, tb_area);
    #1;
  end

`ifdef AREA_PAT0
  localparam int BUS_W = 16;
  localparam int DATA_W = 32;
`elsif AREA_PAT1
  localparam int BUS_W = 24;
  localparam int DATA_W = 72;
`elsif AREA_PAT2
  localparam int BUS_W = 24;
  localparam int DATA_W = 72;
`else
  initial begin
    $error("Define one of AREA_PAT0, AREA_PAT1, AREA_PAT2");
    $finish;
  end
  localparam int BUS_W = 1;
  localparam int DATA_W = 1;
`endif

  reg clk_i;
  reg rst_n_i;
  reg en_i;
  reg config_di_i;
  reg config_shift_en_i;
  reg context_id_i;
  wire config_do_o;
  reg [BUS_W-1:0] north_bus_i;
  reg [BUS_W-1:0] south_bus_i;
  reg [BUS_W-1:0] east_bus_i;
  reg [BUS_W-1:0] west_bus_i;
  wire [DATA_W-1:0] pe_data_o;

`ifdef AREA_PAT0
  area_pat0_top dut (
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
`elsif AREA_PAT1
  area_pat1_top dut (
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
`elsif AREA_PAT2
  area_pat2_top dut (
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
`endif

endmodule
