from dataclasses import dataclass


SEL_NORTH = 0b00
SEL_SOUTH = 0b01
SEL_EAST = 0b10
SEL_WEST = 0b11

OP_ADD = 0b00
OP_SUB = 0b01
OP_MUL = 0b10
OP_ZERO = 0b11

PE_ORDER = ("pe00", "pe01", "pe10", "pe11")
SHIFT_LOAD_ORDER = tuple(reversed(PE_ORDER))


def _alu(op, x, y):
    if op == OP_ADD:
        return (x + y) & 0xFF
    if op == OP_SUB:
        return (x - y) & 0xFF
    if op == OP_MUL:
        return (x * y) & 0xFF
    return 0


@dataclass(frozen=True)
class PEConfig:
    sel_a: int
    sel_b: int
    op: int

    def encode(self):
        return ((self.sel_a & 0b11) << 4) | ((self.sel_b & 0b11) << 2) | (self.op & 0b11)


@dataclass(frozen=True)
class MappingCase:
    name: str
    configs: dict
    cycles: int
    observe: str
    boundary_values: tuple[int, ...]


@dataclass(frozen=True)
class AreaCase:
    name: str
    area_case: str
    rows: int
    cols: int
    contexts: int
    connect_type: str
    cycles: int
    configs: tuple[PEConfig, ...]
    north_bus: tuple[int, ...]
    south_bus: tuple[int, ...]
    east_bus: tuple[int, ...]
    west_bus: tuple[int, ...]
    context_id: int = 0


def pack_bitstream(configs):
    payload = 0
    for index, name in enumerate(SHIFT_LOAD_ORDER):
        payload |= configs[name].encode() << (index * 6)
    return payload


def pack_bitstream_sequence(configs):
    payload = 0
    for index, config in enumerate(reversed(configs)):
        payload |= config.encode() << (index * 6)
    return payload


def mapping_add_then_mul():
    return {
        "pe00": PEConfig(SEL_NORTH, SEL_WEST, OP_ADD),
        "pe01": PEConfig(SEL_WEST, SEL_NORTH, OP_MUL),
        "pe10": PEConfig(SEL_NORTH, SEL_SOUTH, OP_ZERO),
        "pe11": PEConfig(SEL_NORTH, SEL_SOUTH, OP_ZERO),
    }


def golden_add_then_mul(boundary_value):
    add_result = (boundary_value + boundary_value) & 0xFF
    return (add_result * boundary_value) & 0xFF


def mapping_sub_to_pe10():
    return {
        "pe00": PEConfig(SEL_NORTH, SEL_WEST, OP_ADD),
        "pe01": PEConfig(SEL_NORTH, SEL_SOUTH, OP_ZERO),
        "pe10": PEConfig(SEL_NORTH, SEL_WEST, OP_SUB),
        "pe11": PEConfig(SEL_NORTH, SEL_SOUTH, OP_ZERO),
    }


def mapping_fanout_to_pe11():
    return {
        "pe00": PEConfig(SEL_NORTH, SEL_WEST, OP_ADD),
        "pe01": PEConfig(SEL_WEST, SEL_NORTH, OP_ADD),
        "pe10": PEConfig(SEL_NORTH, SEL_SOUTH, OP_ZERO),
        "pe11": PEConfig(SEL_NORTH, SEL_NORTH, OP_ADD),
    }


def mapping_cases():
    return (
        MappingCase(
            name="add_then_mul",
            configs=mapping_add_then_mul(),
            cycles=2,
            observe="pe01",
            boundary_values=(3, 7),
        ),
        MappingCase(
            name="sub_to_pe10",
            configs=mapping_sub_to_pe10(),
            cycles=2,
            observe="pe10",
            boundary_values=(5, 11),
        ),
        MappingCase(
            name="fanout_to_pe11",
            configs=mapping_fanout_to_pe11(),
            cycles=3,
            observe="pe11",
            boundary_values=(4, 9),
        ),
    )


def area_cases():
    return {
        "pat0": AreaCase(
            name="area_pat0_chain_mix",
            area_case="pat0",
            rows=2,
            cols=2,
            contexts=2,
            connect_type="NSWE",
            cycles=3,
            configs=(
                PEConfig(SEL_NORTH, SEL_WEST, OP_ADD),
                PEConfig(SEL_NORTH, SEL_WEST, OP_ADD),
                PEConfig(SEL_NORTH, SEL_WEST, OP_SUB),
                PEConfig(SEL_NORTH, SEL_WEST, OP_ADD),
            ),
            north_bus=(2, 5),
            south_bus=(0, 0),
            east_bus=(0, 0),
            west_bus=(7, 3),
        ),
        "pat1": AreaCase(
            name="area_pat1_vertical_ns",
            area_case="pat1",
            rows=3,
            cols=3,
            contexts=2,
            connect_type="NS",
            cycles=3,
            configs=tuple(PEConfig(SEL_NORTH, SEL_WEST, OP_ADD) for _ in range(9)),
            north_bus=(1, 3, 5),
            south_bus=(0, 0, 0),
            east_bus=(9, 9, 9),
            west_bus=(7, 7, 7),
        ),
        "pat2": AreaCase(
            name="area_pat2_nswe_fanout",
            area_case="pat2",
            rows=3,
            cols=3,
            contexts=1,
            connect_type="NSWE",
            cycles=4,
            configs=(
                PEConfig(SEL_NORTH, SEL_WEST, OP_ADD),
                PEConfig(SEL_NORTH, SEL_WEST, OP_ADD),
                PEConfig(SEL_NORTH, SEL_WEST, OP_ADD),
                PEConfig(SEL_NORTH, SEL_SOUTH, OP_ZERO),
                PEConfig(SEL_NORTH, SEL_WEST, OP_ADD),
                PEConfig(SEL_NORTH, SEL_SOUTH, OP_ZERO),
                PEConfig(SEL_NORTH, SEL_SOUTH, OP_ZERO),
                PEConfig(SEL_NORTH, SEL_SOUTH, OP_ZERO),
                PEConfig(SEL_NORTH, SEL_SOUTH, OP_ZERO),
            ),
            north_bus=(1, 2, 3),
            south_bus=(0, 0, 0),
            east_bus=(0, 0, 0),
            west_bus=(4, 0, 0),
        ),
    }


def evaluate_mesh(rows, cols, configs, north_bus, south_bus, east_bus, west_bus, cycles, connect_type="NSWE"):
    state = [[0 for _ in range(cols)] for _ in range(rows)]
    history = []

    for _ in range(cycles):
        next_state = [[0 for _ in range(cols)] for _ in range(rows)]
        for row in range(rows):
            for col in range(cols):
                cfg = configs[(row * cols) + col]
                north = north_bus[col] if row == 0 else state[row - 1][col]
                south = south_bus[col] if row == rows - 1 else state[row + 1][col]

                if connect_type == "NS":
                    east = 0
                    west = 0
                else:
                    east = east_bus[row] if col == cols - 1 else state[row][col + 1]
                    west = west_bus[row] if col == 0 else state[row][col - 1]

                next_state[row][col] = _alu(
                    cfg.op,
                    _select(cfg.sel_a, north, south, east, west),
                    _select(cfg.sel_b, north, south, east, west),
                )

        state = next_state
        flat_state = {}
        xor_value = 0
        for row in range(rows):
            for col in range(cols):
                key = f"pe{row}{col}"
                value = state[row][col]
                flat_state[key] = value
                xor_value ^= value

        flat_state["xor"] = xor_value
        history.append(flat_state)

    return history


def evaluate_array(configs, boundary_value, cycles):
    north_0 = boundary_value
    north_1 = boundary_value
    west_0 = boundary_value
    west_1 = boundary_value
    south_0 = 0
    south_1 = 0
    east_0 = 0
    east_1 = 0

    state = {
        "pe00": 0,
        "pe01": 0,
        "pe10": 0,
        "pe11": 0,
    }

    history = []
    for _ in range(cycles):
        next_state = {
            "pe00": _alu(
                configs["pe00"].op,
                _select(configs["pe00"].sel_a, north_0, state["pe10"], state["pe01"], west_0),
                _select(configs["pe00"].sel_b, north_0, state["pe10"], state["pe01"], west_0),
            ),
            "pe01": _alu(
                configs["pe01"].op,
                _select(configs["pe01"].sel_a, north_1, state["pe11"], east_0, state["pe00"]),
                _select(configs["pe01"].sel_b, north_1, state["pe11"], east_0, state["pe00"]),
            ),
            "pe10": _alu(
                configs["pe10"].op,
                _select(configs["pe10"].sel_a, state["pe00"], south_0, state["pe11"], west_1),
                _select(configs["pe10"].sel_b, state["pe00"], south_0, state["pe11"], west_1),
            ),
            "pe11": _alu(
                configs["pe11"].op,
                _select(configs["pe11"].sel_a, state["pe01"], south_1, east_1, state["pe10"]),
                _select(configs["pe11"].sel_b, state["pe01"], south_1, east_1, state["pe10"]),
            ),
        }
        state = next_state
        history.append(
            {
                "pe00": state["pe00"],
                "pe01": state["pe01"],
                "pe10": state["pe10"],
                "pe11": state["pe11"],
                "xor": state["pe00"] ^ state["pe01"] ^ state["pe10"] ^ state["pe11"],
            }
        )

    return history


def _select(sel, north, south, east, west):
    if sel == SEL_NORTH:
        return north
    if sel == SEL_SOUTH:
        return south
    if sel == SEL_EAST:
        return east
    return west
