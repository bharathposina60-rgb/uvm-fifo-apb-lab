// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/apb_driver.sv
// SETUP (PSEL=1,PENABLE=0) then ACCESS (PENABLE=1) until PREADY, then idle.
// No objections in the driver.

class apb_driver extends uvm_driver #(apb_item);
  `uvm_component_utils(apb_driver)

  virtual apb_if #(.ADDR_WIDTH(APB_ADDR_WIDTH), .DATA_WIDTH(APB_DATA_WIDTH)) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if #(.ADDR_WIDTH(APB_ADDR_WIDTH),
                                         .DATA_WIDTH(APB_DATA_WIDTH)))::get(
          this, "", "vif", vif))
      `uvm_fatal("NOVIF", "apb_if not set for apb_driver")
  endfunction

  task run_phase(uvm_phase phase);
    idle();
    @(posedge vif.PRESETn);
    repeat (2) @(vif.drv_cb);
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  task idle();
    vif.PSEL    <= 1'b0;
    vif.PENABLE <= 1'b0;
    vif.PWRITE  <= 1'b0;
    vif.PADDR   <= '0;
    vif.PWDATA  <= '0;
  endtask

  task drive_item(apb_item req);
    int unsigned i;
    @(vif.drv_cb);
    vif.drv_cb.PSEL    <= 1'b1;
    vif.drv_cb.PENABLE <= 1'b0;
    vif.drv_cb.PWRITE  <= req.write;
    vif.drv_cb.PADDR   <= req.addr;
    vif.drv_cb.PWDATA  <= req.data;
    @(vif.drv_cb);
    vif.drv_cb.PENABLE <= 1'b1;
    for (i = 0; i < req.wait_states; i++)
      @(vif.drv_cb);
    while (!vif.drv_cb.PREADY)
      @(vif.drv_cb);
    req.rdata  = vif.drv_cb.PRDATA;
    req.slverr = vif.drv_cb.PSLVERR;
    @(vif.drv_cb);
    vif.drv_cb.PSEL    <= 1'b0;
    vif.drv_cb.PENABLE <= 1'b0;
    vif.drv_cb.PWRITE  <= 1'b0;
  endtask
endclass
