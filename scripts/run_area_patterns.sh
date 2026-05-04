#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

for pattern in 0 1 2; do
    case "$pattern" in
        0) name="2x2_NSWE_Ctx2" ;;
        1) name="3x3_NS_Ctx2" ;;
        2) name="3x3_NSWE_Ctx1" ;;
    esac

    echo "=== $name (PATTERN=$pattern) ==="
    yosys -Q -p "read_verilog -sv src/alu.sv; read_verilog -sv src/pe.sv; read_verilog -sv src/pe_array_mesh.sv; read_verilog -sv src/area_bench_top.sv; chparam -set PATTERN $pattern area_bench_top; hierarchy -top area_bench_top; proc; flatten; opt; techmap; opt; stat"
    echo
done
