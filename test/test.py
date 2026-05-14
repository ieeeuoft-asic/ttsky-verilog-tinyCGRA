# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import ReadOnly

from cgra_model import evaluate_array
from cgra_model import mapping_cases
from cgra_model import pack_bitstream


CFG_MODE = 1 << 5
LOAD_INPUT = 1 << 6
DEBUG_XOR = 1 << 7
RUN_EN = 1 << 2
PE_SELECT = {"pe00": 0b00, "pe01": 0b01, "pe10": 0b10, "pe11": 0b11}


async def shift_payload(dut, payload, total_bits):
    for bit_idx in range(total_bits):
        dut.ui_in.value = 0
        dut.uio_in.value = CFG_MODE | (1 << 1) | (((payload >> bit_idx) & 1) << 0)
        await ReadOnly()
        assert int(dut.uio_oe.value) == 0
        await ClockCycles(dut.clk, 1)

    dut.uio_in.value = 0
    await ReadOnly()
    assert int(dut.uio_oe.value) == 0b0000_0011
    # assert int(dut.uio_out.value) & 0b10 == 0b10
    await ClockCycles(dut.clk, 1)

    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)


async def load_input(dut, value):
    dut.ui_in.value = value
    dut.uio_in.value = LOAD_INPUT
    await ReadOnly()
    # assert int(dut.user_project.load_input.value) == 1
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)


async def reset_dut(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)


def cycle_trace(dut):
    top = dut.user_project
    return {
        "pe00": int(top.pe_data_00.value),
        "pe01": int(top.pe_data_01.value),
        "pe10": int(top.pe_data_10.value),
        "pe11": int(top.pe_data_11.value),
    }


async def run_case(dut, case, boundary_value):
    await reset_dut(dut)

    payload = pack_bitstream(case.configs)
    total_bits = 6 * len(case.configs)
    dut._log.info(f"{case.name}: shift payload 0x{payload:06x} for input {boundary_value}")
    await shift_payload(dut, payload, total_bits)

    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.uio_oe.value) == 0b0000_0011
    assert int(dut.uio_out.value) & 0b10 == 0

    await load_input(dut, boundary_value)
    assert int(dut.user_project.input_reg.value) == boundary_value

    expected_history = evaluate_array(case.configs, boundary_value, cycles=case.cycles)
    observe_sel = PE_SELECT[case.observe] << 3
    dut.uio_in.value = RUN_EN | observe_sel
    await ReadOnly()
    assert int(dut.user_project.run_en.value) == 1

    for cycle_idx in range(case.cycles + 1):
        await ClockCycles(dut.clk, 1)
        trace = cycle_trace(dut)
        dut._log.info(f"{case.name}: cycle {cycle_idx} trace {trace}")
        if cycle_idx == 0:
            assert trace == {"pe00": 0, "pe01": 0, "pe10": 0, "pe11": 0}
            continue

        expected = expected_history[cycle_idx - 1]
        assert trace == {k: expected[k] for k in ("pe00", "pe01", "pe10", "pe11")}
        assert int(dut.uo_out.value) == expected[case.observe]

    dut.uio_in.value = DEBUG_XOR
    await ClockCycles(dut.clk, 1)
    assert int(dut.uo_out.value) == expected_history[-1]["xor"]


@cocotb.test()
async def test_mapping_suite(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    for case in mapping_cases():
        for boundary_value in case.boundary_values:
            await run_case(dut, case, boundary_value)
