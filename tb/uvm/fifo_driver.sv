// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/fifo_driver.sv
// Pull req, drive one cycle, item_done. No objections in the driver.

class fifo_driver extends uvm_driver #(fifo_item);
  `uvm_component_utils(fifo_driver)

  virtual fifo_if #(.WIDTH(FIFO_WIDTH), .DEPTH(FIFO_DEPTH)) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if #(.WIDTH(FIFO_WIDTH), .DEPTH(FIFO_DEPTH)))::get(
          this, "", "vif", vif))
      `uvm_fatal("NOVIF", "fifo_if not set for fifo_driver")
  endfunction

  task run_phase(uvm_phase phase);
    vif.wr_en <= 1'b0;
    vif.rd_en <= 1'b0;
    vif.wdata <= '0;
    @(posedge vif.rst_n);
    repeat (2) @(vif.drv_cb);
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_item(fifo_item req);
    @(vif.drv_cb);
    vif.drv_cb.wr_en <= req.wr;
    vif.drv_cb.rd_en <= req.rd;
    vif.drv_cb.wdata <= req.data;
    @(vif.drv_cb);
    vif.drv_cb.wr_en <= 1'b0;
    vif.drv_cb.rd_en <= 1'b0;
    req.rdata = vif.drv_cb.rdata;
    req.full  = vif.drv_cb.full;
    req.empty = vif.drv_cb.empty;
  endtask
endclass
