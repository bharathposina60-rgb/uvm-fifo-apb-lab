// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/fifo_monitor.sv
// Passive. Reconstructs a transaction from the handshake.
// Handshake (wr/rd/full/empty/wdata) is sampled at posedge (the same
// values the DUT always_ff uses). rdata is sampled #1step later so the
// registered read data of that cycle is visible.

class fifo_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_monitor)

  virtual fifo_if #(.WIDTH(FIFO_WIDTH), .DEPTH(FIFO_DEPTH)) vif;
  uvm_analysis_port #(fifo_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if #(.WIDTH(FIFO_WIDTH), .DEPTH(FIFO_DEPTH)))::get(
          this, "", "vif", vif))
      `uvm_fatal("NOVIF", "fifo_if not set for fifo_monitor")
  endfunction

  task run_phase(uvm_phase phase);
    fifo_item item;
    bit wr, rd, full, empty;
    bit [FIFO_WIDTH-1:0] wdata, rdata;
    @(posedge vif.rst_n);
    forever begin
      @(posedge vif.clk);
      if (!vif.rst_n) continue;
      wr    = vif.wr_en;
      rd    = vif.rd_en;
      full  = vif.full;
      empty = vif.empty;
      wdata = vif.wdata;
      #1step;
      rdata = vif.rdata;
      if (!(wr || rd)) continue;
      item = fifo_item::type_id::create("item");
      item.wr    = wr;
      item.rd    = rd;
      item.data  = wdata;
      item.rdata = rdata;
      item.full  = full;
      item.empty = empty;
      ap.write(item);
    end
  endtask
endclass
