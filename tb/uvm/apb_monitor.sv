// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/apb_monitor.sv
// Reconstruct SETUP -> ACCESS -> PREADY. Do not drive. Do not score.

class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  virtual apb_if #(.ADDR_WIDTH(APB_ADDR_WIDTH), .DATA_WIDTH(APB_DATA_WIDTH)) vif;
  uvm_analysis_port #(apb_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if #(.ADDR_WIDTH(APB_ADDR_WIDTH),
                                         .DATA_WIDTH(APB_DATA_WIDTH)))::get(
          this, "", "vif", vif))
      `uvm_fatal("NOVIF", "apb_if not set for apb_monitor")
  endfunction

  task run_phase(uvm_phase phase);
    apb_item item;
    @(posedge vif.PRESETn);
    forever begin
      @(vif.mon_cb);
      if (!vif.PRESETn) continue;
      if (!(vif.mon_cb.PSEL && !vif.mon_cb.PENABLE)) continue;
      // SETUP observed. Wait for ACCESS + PREADY.
      do @(vif.mon_cb);
      while (!(vif.mon_cb.PSEL && vif.mon_cb.PENABLE && vif.mon_cb.PREADY));
      item = apb_item::type_id::create("item");
      item.write  = vif.mon_cb.PWRITE;
      item.addr   = vif.mon_cb.PADDR;
      item.data   = vif.mon_cb.PWDATA;
      item.rdata  = vif.mon_cb.PRDATA;
      item.slverr = vif.mon_cb.PSLVERR;
      ap.write(item);
    end
  endtask
endclass
