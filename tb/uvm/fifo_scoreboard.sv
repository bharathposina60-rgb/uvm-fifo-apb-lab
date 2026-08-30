// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/fifo_scoreboard.sv
// Queue model. Writes accepted only when !full; reads when !empty.
// Simultaneous: pop then push (matches DUT: both do_wr and do_rd fire).

class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp #(fifo_item, fifo_scoreboard) imp;
  bit [FIFO_WIDTH-1:0] q[$];
  int unsigned n_write;
  int unsigned n_read;
  int unsigned n_mismatch;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    imp = new("imp", this);
  endfunction

  function void write(fifo_item t);
    bit [FIFO_WIDTH-1:0] exp;
    if (t.rd && !t.empty) begin
      if (q.size() == 0) begin
        `uvm_error("FIFO_SB", "DUT read while model empty")
        n_mismatch++;
      end else begin
        exp = q.pop_front();
        if (t.rdata !== exp) begin
          `uvm_error("FIFO_SB",
            $sformatf("rdata mismatch exp=0x%0h got=0x%0h", exp, t.rdata))
          n_mismatch++;
        end
        n_read++;
      end
    end
    if (t.wr && !t.full) begin
      q.push_back(t.data);
      n_write++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("FIFO_SB",
      $sformatf("writes=%0d reads=%0d mismatches=%0d residual=%0d",
                n_write, n_read, n_mismatch, q.size()), UVM_LOW)
    if (n_mismatch != 0)
      `uvm_error("FIFO_SB", "scoreboard recorded mismatches")
  endfunction
endclass
