// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/apb_item.sv

class apb_item extends uvm_sequence_item;
  rand bit                      write;
  rand bit [APB_ADDR_WIDTH-1:0] addr;
  rand bit [APB_DATA_WIDTH-1:0] data;
  bit [APB_DATA_WIDTH-1:0]      rdata;
  bit                           slverr;
  rand int unsigned             wait_states;

  `uvm_object_utils_begin(apb_item)
    `uvm_field_int(write,       UVM_ALL_ON)
    `uvm_field_int(addr,        UVM_ALL_ON)
    `uvm_field_int(data,        UVM_ALL_ON)
    `uvm_field_int(rdata,       UVM_ALL_ON)
    `uvm_field_int(slverr,      UVM_ALL_ON)
    `uvm_field_int(wait_states, UVM_ALL_ON)
  `uvm_object_utils_end

  constraint c_wait { wait_states inside {[0:16]}; }
  // Prefer legal word-aligned addresses; sequences may override for PSLVERR.
  constraint c_align { addr[1:0] == 2'b00; }

  function new(string name = "apb_item");
    super.new(name);
  endfunction
endclass
