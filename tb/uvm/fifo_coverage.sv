// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/fifo_coverage.sv
// Named bins only. No implicit bins others as the sole closure.

class fifo_coverage extends uvm_subscriber #(fifo_item);
  `uvm_component_utils(fifo_coverage)

  fifo_item item;

  covergroup fifo_cg;
    option.per_instance = 1;

    cp_wr: coverpoint item.wr {
      bins bin_no_wr = {0};
      bins bin_wr    = {1};
    }
    cp_rd: coverpoint item.rd {
      bins bin_no_rd = {0};
      bins bin_rd    = {1};
    }
    cp_full: coverpoint item.full {
      bins bin_not_full = {0};
      bins bin_full     = {1};
    }
    cp_empty: coverpoint item.empty {
      bins bin_not_empty = {0};
      bins bin_empty     = {1};
    }
    cx_op_flags: cross cp_wr, cp_rd, cp_full, cp_empty {
      bins bin_write_ok  = binsof(cp_wr.bin_wr) && binsof(cp_rd.bin_no_rd) &&
                           binsof(cp_full.bin_not_full);
      bins bin_read_ok   = binsof(cp_rd.bin_rd) && binsof(cp_wr.bin_no_wr) &&
                           binsof(cp_empty.bin_not_empty);
      bins bin_both_ok   = binsof(cp_wr.bin_wr) && binsof(cp_rd.bin_rd) &&
                           binsof(cp_full.bin_not_full) && binsof(cp_empty.bin_not_empty);
      bins bin_wr_full   = binsof(cp_wr.bin_wr) && binsof(cp_full.bin_full);
      bins bin_rd_empty  = binsof(cp_rd.bin_rd) && binsof(cp_empty.bin_empty);
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    fifo_cg = new();
  endfunction

  function void write(fifo_item t);
    item = t;
    fifo_cg.sample();
  endfunction
endclass
