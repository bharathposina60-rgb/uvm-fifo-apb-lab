// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/apb_seq_lib.sv

class apb_write_seq extends uvm_sequence #(apb_item);
  `uvm_object_utils(apb_write_seq)
  rand bit [APB_ADDR_WIDTH-1:0] addr;
  rand bit [APB_DATA_WIDTH-1:0] data;
  function new(string name = "apb_write_seq");
    super.new(name);
  endfunction
  task body();
    req = apb_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { write == 1; addr == local::addr; data == local::data; wait_states == 0; })
      `uvm_fatal("RAND", "apb_write_seq randomize failed")
    finish_item(req);
  endtask
endclass

class apb_read_seq extends uvm_sequence #(apb_item);
  `uvm_object_utils(apb_read_seq)
  rand bit [APB_ADDR_WIDTH-1:0] addr;
  function new(string name = "apb_read_seq");
    super.new(name);
  endfunction
  task body();
    req = apb_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { write == 0; addr == local::addr; wait_states == 0; })
      `uvm_fatal("RAND", "apb_read_seq randomize failed")
    finish_item(req);
  endtask
endclass

class apb_mem_walk_seq extends uvm_sequence #(apb_item);
  `uvm_object_utils(apb_mem_walk_seq)
  function new(string name = "apb_mem_walk_seq");
    super.new(name);
  endfunction
  task body();
    int i;
    apb_write_seq wr;
    apb_read_seq  rd;
    for (i = 0; i < APB_WORDS; i++) begin
      wr = apb_write_seq::type_id::create("wr");
      wr.addr = APB_ADDR_WIDTH'(i << 2);
      wr.data = APB_DATA_WIDTH'(32'hA5A50000 + i);
      wr.start(m_sequencer);
    end
    for (i = 0; i < APB_WORDS; i++) begin
      rd = apb_read_seq::type_id::create("rd");
      rd.addr = APB_ADDR_WIDTH'(i << 2);
      rd.start(m_sequencer);
    end
  endtask
endclass

class apb_wait_state_seq extends uvm_sequence #(apb_item);
  `uvm_object_utils(apb_wait_state_seq)
  function new(string name = "apb_wait_state_seq");
    super.new(name);
  endfunction
  task body();
    // DUT has 0-wait PREADY. The extra wait_states are idle ACCESS cycles
    // the driver inserts; PREADY is already 1, so they are extra beats.
    repeat (4) begin
      req = apb_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
            addr[7:6] == 2'b00;
            addr[1:0] == 2'b00;
            wait_states inside {[0:2]};
          })
        `uvm_fatal("RAND", "apb_wait_state_seq randomize failed")
      finish_item(req);
    end
  endtask
endclass

class apb_slverr_seq extends uvm_sequence #(apb_item);
  `uvm_object_utils(apb_slverr_seq)
  function new(string name = "apb_slverr_seq");
    super.new(name);
  endfunction
  task body();
    req = apb_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { write == 1; addr == 8'h40; data == 32'hDEADBEEF; wait_states == 0; })
      `uvm_fatal("RAND", "apb_slverr_seq randomize failed")
    finish_item(req);
    req = apb_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { write == 0; addr == 8'h40; wait_states == 0; })
      `uvm_fatal("RAND", "apb_slverr_seq randomize failed")
    finish_item(req);
  endtask
endclass

class apb_mem_test_seq extends uvm_sequence #(apb_item);
  `uvm_object_utils(apb_mem_test_seq)
  function new(string name = "apb_mem_test_seq");
    super.new(name);
  endfunction
  task body();
    apb_mem_walk_seq   walk;
    apb_slverr_seq     oob;
    apb_wait_state_seq ws;
    walk = apb_mem_walk_seq::type_id::create("walk");
    oob  = apb_slverr_seq::type_id::create("oob");
    ws   = apb_wait_state_seq::type_id::create("ws");
    walk.start(m_sequencer);
    oob.start(m_sequencer);
    ws.start(m_sequencer);
  endtask
endclass
