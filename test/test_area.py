# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from cgra_model import area_cases
from cgra_model import evaluate_mesh
from cgra_model import PEConfig
from cgra_model import pack_bitstream_sequence


def _env_area_case():
    case_name = os.getenv("AREA_CASE")
    if not case_name:
        raise RuntimeError("AREA_CASE must be set for area testbench runs")
    return case_name


def _flatten_bus(values, width=8):
    packed = 0
    for index, value in enumerate(values):
        packed |= (value & ((1 << width) - 1)) << (index * width)
    return packed


def _trace_pe_data(dut, rows, cols):
    trace = {}
    for row in range(rows):
        for col in range(cols):
            index = (row * cols) + col
            trace[f"pe{row}{col}"] = int(dut.pe_data_o.value[(index + 1) * 8 - 1:index * 8])
    return trace


async def _reset_area_dut(dut, context_id):
    dut.en_i.value = 0
    dut.config_di_i.value = 0
    dut.config_shift_en_i.value = 0
    dut.context_id_i.value = context_id
    dut.north_bus_i.value = 0
    dut.south_bus_i.value = 0
    dut.east_bus_i.value = 0
    dut.west_bus_i.value = 0
    dut.rst_n_i.value = 0
    await ClockCycles(dut.clk_i, 5)
    dut.rst_n_i.value = 1
    await ClockCycles(dut.clk_i, 1)


async def _shift_area_payload(dut, payload, total_bits):
    for bit_idx in range(total_bits):
        dut.config_di_i.value = (payload >> bit_idx) & 1
        dut.config_shift_en_i.value = 1
        await ClockCycles(dut.clk_i, 1)

    dut.config_di_i.value = 0
    dut.config_shift_en_i.value = 0
    await ClockCycles(dut.clk_i, 1)


def _build_context_payload(case):
    zero_cfg = PEConfig(0, 0, 0)
    config_sequence = []
    for cfg in case.configs:
        for ctx_idx in range(case.contexts):
            if ctx_idx == case.context_id:
                config_sequence.append(cfg)
            else:
                config_sequence.append(zero_cfg)
    return pack_bitstream_sequence(tuple(config_sequence))


@cocotb.test()
async def test_area_top(dut):
    case = area_cases()[_env_area_case()]

    clock = Clock(dut.clk_i, 10, unit="us")
    cocotb.start_soon(clock.start())

    await _reset_area_dut(dut, case.context_id)

    payload = _build_context_payload(case)
    total_bits = 6 * len(case.configs) * case.contexts
    dut._log.info(f"{case.name}: shift payload 0x{payload:x}")
    await _shift_area_payload(dut, payload, total_bits)

    dut.north_bus_i.value = _flatten_bus(case.north_bus)
    dut.south_bus_i.value = _flatten_bus(case.south_bus)
    dut.east_bus_i.value = _flatten_bus(case.east_bus)
    dut.west_bus_i.value = _flatten_bus(case.west_bus)

    expected_history = evaluate_mesh(
        rows=case.rows,
        cols=case.cols,
        configs=case.configs,
        north_bus=case.north_bus,
        south_bus=case.south_bus,
        east_bus=case.east_bus,
        west_bus=case.west_bus,
        cycles=case.cycles,
        connect_type=case.connect_type,
    )

    for cycle_idx in range(case.cycles + 1):
        dut.en_i.value = 1
        await ClockCycles(dut.clk_i, 1)
        dut.en_i.value = 0

        trace = _trace_pe_data(dut, case.rows, case.cols)
        dut._log.info(f"{case.name}: cycle {cycle_idx} trace {trace}")
        if cycle_idx == 0:
            assert all(value == 0 for value in trace.values())
            continue

        expected = expected_history[cycle_idx - 1]
        assert trace == {k: expected[k] for k in trace}
