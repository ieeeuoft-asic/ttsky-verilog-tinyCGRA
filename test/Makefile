# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
AREA_CASE ?=

ifeq ($(AREA_CASE),)
PROJECT_SOURCES = project.v alu.sv pe.sv pe_array_mesh.sv

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)
COMPILE_ARGS    += -g2012

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

else

SIM_BUILD = sim_build/$(AREA_CASE)
PROJECT_SOURCES = alu.sv pe.sv pe_array_mesh.sv area_bench_top.sv
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
VERILOG_SOURCES += $(PWD)/tb_area.v
TOPLEVEL = tb_area
COCOTB_TEST_MODULES = test_area
export AREA_CASE

ifeq ($(AREA_CASE),pat0)
VERILOG_SOURCES += $(SRC_DIR)/area_pat0_top.sv
COMPILE_ARGS += -DAREA_PAT0
else ifeq ($(AREA_CASE),pat1)
VERILOG_SOURCES += $(SRC_DIR)/area_pat1_top.sv
COMPILE_ARGS += -DAREA_PAT1
else ifeq ($(AREA_CASE),pat2)
VERILOG_SOURCES += $(SRC_DIR)/area_pat2_top.sv
COMPILE_ARGS += -DAREA_PAT2
else
$(error Unsupported AREA_CASE '$(AREA_CASE)'; use pat0, pat1, or pat2)
endif

endif

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
