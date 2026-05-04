#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

COMMON_READS="read_verilog -sv src/alu.sv; read_verilog -sv src/pe.sv; read_verilog -sv src/pe_array_mesh.sv"

run_top() {
    top_name="$1"
    extra_reads="$2"

    echo "=== $top_name ==="
    yosys -Q -p "$COMMON_READS; $extra_reads; hierarchy -top $top_name; proc; flatten; opt; techmap; opt; stat"
    echo
}

run_top "area_pat0_top" "read_verilog -sv src/area_bench_top.sv; read_verilog -sv src/area_pat0_top.sv"
run_top "area_pat1_top" "read_verilog -sv src/area_bench_top.sv; read_verilog -sv src/area_pat1_top.sv"
run_top "area_pat2_top" "read_verilog -sv src/area_bench_top.sv; read_verilog -sv src/area_pat2_top.sv"
run_top "cgra_3x3_ctx2_top" "read_verilog -sv src/cgra_3x3_top.sv; read_verilog -sv src/cgra_3x3_ctx2_top.sv"
