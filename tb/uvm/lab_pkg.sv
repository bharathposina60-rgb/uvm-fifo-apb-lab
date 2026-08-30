// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
//
// file: tb/uvm/lab_pkg.sv
// UVM 1.2 package. Compile with +define+UVM and a UVM 1.2 library.
// Verilator CI does not compile this file.
//
`ifndef LAB_PKG_SV
`define LAB_PKG_SV

`ifdef UVM
package lab_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  localparam int FIFO_WIDTH     = 8;
  localparam int FIFO_DEPTH     = 16;
  localparam int APB_ADDR_WIDTH = 8;
  localparam int APB_DATA_WIDTH = 32;
  localparam int APB_WORDS      = 16;

  `include "fifo_item.sv"
  `include "fifo_sequencer.sv"
  `include "fifo_driver.sv"
  `include "fifo_monitor.sv"
  `include "fifo_agent.sv"
  `include "fifo_scoreboard.sv"
  `include "fifo_coverage.sv"
  `include "fifo_seq_lib.sv"

  `include "apb_item.sv"
  `include "apb_sequencer.sv"
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_agent.sv"
  `include "apb_scoreboard.sv"
  `include "apb_coverage.sv"
  `include "apb_seq_lib.sv"

  `include "lab_env.sv"
  `include "lab_test.sv"
endpackage
`else
  // Intentionally empty when compiled without +define+UVM so a stray
  // include does not pull Accellera class syntax into Verilator.
`endif

`endif
