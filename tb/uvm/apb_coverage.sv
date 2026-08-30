// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/apb_coverage.sv
// Named bins only.

class apb_coverage extends uvm_subscriber #(apb_item);
  `uvm_component_utils(apb_coverage)

  apb_item item;

  covergroup apb_cg;
    option.per_instance = 1;

    cp_write: coverpoint item.write {
      bins bin_read  = {0};
      bins bin_write = {1};
    }
    cp_word: coverpoint item.addr[5:2] {
      bins bin_word[] = {[0:15]};
    }
    cp_hi: coverpoint item.addr[7:6] {
      bins bin_in_map  = {2'b00};
      bins bin_oob_hi  = {2'b01};
      bins bin_oob_far = {2'b10, 2'b11};
    }
    cp_slverr: coverpoint item.slverr {
      bins bin_ok     = {0};
      bins bin_slverr = {1};
    }
    cx_rw_word: cross cp_write, cp_word;
    cx_err:     cross cp_write, cp_hi, cp_slverr {
      bins bin_legal_ok = binsof(cp_hi.bin_in_map) && binsof(cp_slverr.bin_ok);
      bins bin_oob_err  = binsof(cp_hi.bin_oob_hi) && binsof(cp_slverr.bin_slverr);
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    apb_cg = new();
  endfunction

  function void write(apb_item t);
    item = t;
    apb_cg.sample();
  endfunction
endclass
