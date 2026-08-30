// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/fifo_item.sv
// Included from lab_pkg. Assumptions: WIDTH from lab_pkg localparam.

class fifo_item extends uvm_sequence_item;
  rand bit              wr;
  rand bit              rd;
  rand bit [FIFO_WIDTH-1:0] data;
  bit [FIFO_WIDTH-1:0]  rdata;
  bit                   full;
  bit                   empty;

  `uvm_object_utils_begin(fifo_item)
    `uvm_field_int(wr,    UVM_ALL_ON)
    `uvm_field_int(rd,    UVM_ALL_ON)
    `uvm_field_int(data,  UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_field_int(full,  UVM_ALL_ON)
    `uvm_field_int(empty, UVM_ALL_ON)
  `uvm_object_utils_end

  constraint c_legal_op { wr || rd; }

  function new(string name = "fifo_item");
    super.new(name);
  endfunction
endclass
