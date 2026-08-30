// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/fifo_seq_lib.sv
// start_item / randomize / finish_item. Never $random.

class fifo_smoke_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_smoke_seq)
  function new(string name = "fifo_smoke_seq");
    super.new(name);
  endfunction
  task body();
    repeat (8) begin
      req = fifo_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { wr != rd; })
        `uvm_fatal("RAND", "fifo_smoke_seq randomize failed")
      finish_item(req);
    end
  endtask
endclass

class fifo_fill_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_fill_seq)
  function new(string name = "fifo_fill_seq");
    super.new(name);
  endfunction
  task body();
    int i;
    for (i = 0; i < FIFO_DEPTH; i++) begin
      req = fifo_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { wr == 1; rd == 0; data == FIFO_WIDTH'(8'hA0 + i); })
        `uvm_fatal("RAND", "fifo_fill_seq randomize failed")
      finish_item(req);
    end
  endtask
endclass

class fifo_drain_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_drain_seq)
  function new(string name = "fifo_drain_seq");
    super.new(name);
  endfunction
  task body();
    repeat (FIFO_DEPTH) begin
      req = fifo_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { wr == 0; rd == 1; })
        `uvm_fatal("RAND", "fifo_drain_seq randomize failed")
      finish_item(req);
    end
  endtask
endclass

class fifo_simultaneous_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_simultaneous_seq)
  function new(string name = "fifo_simultaneous_seq");
    super.new(name);
  endfunction
  task body();
    repeat (8) begin
      req = fifo_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { wr == 1; rd == 1; })
        `uvm_fatal("RAND", "fifo_simultaneous_seq randomize failed")
      finish_item(req);
    end
  endtask
endclass

class fifo_fill_empty_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_fill_empty_seq)
  function new(string name = "fifo_fill_empty_seq");
    super.new(name);
  endfunction
  task body();
    fifo_fill_seq         fill;
    fifo_drain_seq        drain;
    fifo_simultaneous_seq both;
    fifo_smoke_seq        smoke;
    fill  = fifo_fill_seq::type_id::create("fill");
    drain = fifo_drain_seq::type_id::create("drain");
    both  = fifo_simultaneous_seq::type_id::create("both");
    smoke = fifo_smoke_seq::type_id::create("smoke");
    fill.start(m_sequencer);
    drain.start(m_sequencer);
    fill.start(m_sequencer);
    both.start(m_sequencer);
    drain.start(m_sequencer);
    smoke.start(m_sequencer);
  endtask
endclass
