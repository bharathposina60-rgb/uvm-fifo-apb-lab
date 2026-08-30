# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Bharath Posina
#
# CI entry point: `make sim`
# Requires Verilator 5.x with --binary and --timing (Ubuntu 24.04+ apt is fine).
# The UVM tree under tb/uvm is NOT compiled here.

VERILATOR ?= verilator
TOP       ?= tb_top

RTL := \
	rtl/sync_fifo.sv \
	rtl/apb_slave.sv

TB := \
	tb/verilator/tb_top.sv \
	tb/verilator/fifo_sva.sv \
	tb/verilator/apb_sva.sv

BUILD_DIR := obj_dir
BIN       := $(BUILD_DIR)/V$(TOP)

# --binary implies --cc --exe --main --build
# --timing is required for #delay clock generation
# --assert enables the bind-ready SVA in tb/verilator/*_sva.sv
VL_FLAGS := \
	--binary \
	--timing \
	--assert \
	-sv \
	--top-module $(TOP) \
	--timescale 1ns/1ps \
	-Wall \
	-Wno-fatal \
	-Wno-DECLFILENAME \
	-Wno-UNUSEDSIGNAL \
	-j 0

PLUSARGS ?= +seed=1

.PHONY: all sim waves lint clean help

all: sim

help:
	@echo "make sim     - build with Verilator and run self-checking TB (CI)"
	@echo "make waves   - same, plus +trace -> waves.vcd"
	@echo "make lint    - Verilator lint-only on RTL"
	@echo "make clean   - remove obj_dir, VCD, logs"
	@echo "UVM TB (not CI): see tb/uvm/README.md and tb/uvm/filelist.f"

$(BIN): $(RTL) $(TB)
	$(VERILATOR) $(VL_FLAGS) $(RTL) $(TB)

sim: $(BIN)
	$(BIN) $(PLUSARGS)

waves: VL_FLAGS += --trace
waves: $(RTL) $(TB)
	$(VERILATOR) $(VL_FLAGS) $(RTL) $(TB)
	$(BIN) $(PLUSARGS) +trace

lint:
	$(VERILATOR) --lint-only -sv -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
		--top-module sync_fifo rtl/sync_fifo.sv
	$(VERILATOR) --lint-only -sv -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
		--top-module apb_slave rtl/apb_slave.sv

clean:
	rm -rf $(BUILD_DIR) waves.vcd *.vcd *.log
