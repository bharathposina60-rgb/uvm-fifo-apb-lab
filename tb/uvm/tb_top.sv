// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
//
// file: tb/uvm/tb_top.sv
// UVM 1.2 top. Needs uvm_pkg + a commercial or UVM-compatible simulator.
// Not compiled by `make sim`.
//
`timescale 1ns/1ps

`ifdef UVM
`include "uvm_macros.svh"
import uvm_pkg::*;
import lab_pkg::*;
`endif

module tb_top;

  localparam int WIDTH     = 8;
  localparam int DEPTH     = 16;
  localparam int ADDR_W    = 8;
  localparam int DATA_W    = 32;
  localparam int MEM_WORDS = 16;

  logic clk;
  logic rst_n;

  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
  end

  fifo_if #(.WIDTH(WIDTH), .DEPTH(DEPTH)) fifo_vif (.clk(clk), .rst_n(rst_n));
  apb_if  #(.ADDR_WIDTH(ADDR_W), .DATA_WIDTH(DATA_W)) apb_vif (
    .PCLK(clk), .PRESETn(rst_n)
  );

  sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) u_fifo (
    .clk   (clk),
    .rst_n (rst_n),
    .wr_en (fifo_vif.wr_en),
    .rd_en (fifo_vif.rd_en),
    .wdata (fifo_vif.wdata),
    .rdata (fifo_vif.rdata),
    .full  (fifo_vif.full),
    .empty (fifo_vif.empty),
    .count (fifo_vif.count)
  );

  apb_slave #(.ADDR_WIDTH(ADDR_W), .DATA_WIDTH(DATA_W), .MEM_WORDS(MEM_WORDS)) u_apb (
    .PCLK   (clk),
    .PRESETn(rst_n),
    .PSEL   (apb_vif.PSEL),
    .PENABLE(apb_vif.PENABLE),
    .PWRITE (apb_vif.PWRITE),
    .PADDR  (apb_vif.PADDR),
    .PWDATA (apb_vif.PWDATA),
    .PRDATA (apb_vif.PRDATA),
    .PREADY (apb_vif.PREADY),
    .PSLVERR(apb_vif.PSLVERR)
  );

`ifdef UVM
  initial begin
    uvm_config_db#(virtual fifo_if #(.WIDTH(WIDTH), .DEPTH(DEPTH)))::set(
      null, "*fifo*", "vif", fifo_vif);
    uvm_config_db#(virtual apb_if #(.ADDR_WIDTH(ADDR_W), .DATA_WIDTH(DATA_W)))::set(
      null, "*apb*", "vif", apb_vif);
    run_test("lab_smoke_test");
  end
`endif

endmodule
