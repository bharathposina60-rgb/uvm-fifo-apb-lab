// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/apb_scoreboard.sv
// Shadow memory of the 16-word map. Out-of-range ACCESS must slverr
// and must not update the model.

class apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_scoreboard)

  uvm_analysis_imp #(apb_item, apb_scoreboard) imp;
  bit [APB_DATA_WIDTH-1:0] shadow [int];
  int unsigned n_write;
  int unsigned n_read;
  int unsigned n_slverr;
  int unsigned n_mismatch;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    imp = new("imp", this);
  endfunction

  function bit is_legal(bit [APB_ADDR_WIDTH-1:0] addr);
    return (addr[APB_ADDR_WIDTH-1:6] == '0);
  endfunction

  function void write(apb_item t);
    bit [APB_DATA_WIDTH-1:0] exp;
    int unsigned word;
    word = t.addr[5:2];
    if (!is_legal(t.addr)) begin
      if (t.slverr !== 1'b1) begin
        `uvm_error("APB_SB", $sformatf("expected PSLVERR at addr=0x%0h", t.addr))
        n_mismatch++;
      end
      n_slverr++;
      return;
    end
    if (t.slverr) begin
      `uvm_error("APB_SB", $sformatf("unexpected PSLVERR at legal addr=0x%0h", t.addr))
      n_mismatch++;
      return;
    end
    if (t.write) begin
      shadow[word] = t.data;
      n_write++;
    end else begin
      exp = shadow.exists(word) ? shadow[word] : '0;
      if (t.rdata !== exp) begin
        `uvm_error("APB_SB",
          $sformatf("PRDATA mismatch addr=0x%0h exp=0x%0h got=0x%0h",
                    t.addr, exp, t.rdata))
        n_mismatch++;
      end
      n_read++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("APB_SB",
      $sformatf("writes=%0d reads=%0d slverr=%0d mismatches=%0d",
                n_write, n_read, n_slverr, n_mismatch), UVM_LOW)
    if (n_mismatch != 0)
      `uvm_error("APB_SB", "scoreboard recorded mismatches")
  endfunction
endclass
