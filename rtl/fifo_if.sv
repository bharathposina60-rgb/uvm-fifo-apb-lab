// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
//
// file: rtl/fifo_if.sv
// Generic synchronous FIFO interface (IEEE 1800). Public-safe.
// Clocking blocks are omitted under Verilator; the CI TB drives DUT ports.
//
`timescale 1ns/1ps

interface fifo_if #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16
) (
  input logic clk,
  input logic rst_n
);

  logic                       wr_en;
  logic                       rd_en;
  logic [WIDTH-1:0]           wdata;
  logic [WIDTH-1:0]           rdata;
  logic                       full;
  logic                       empty;
  logic [$clog2(DEPTH+1)-1:0] count;

`ifndef VERILATOR
  clocking drv_cb @(posedge clk);
    default input #1step output #0;
    output wr_en, rd_en, wdata;
    input  rdata, full, empty, count;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input wr_en, rd_en, wdata, rdata, full, empty, count, rst_n;
  endclocking

  modport drv (clocking drv_cb, input clk, rst_n);
  modport mon (clocking mon_cb, input clk, rst_n);
`endif

  modport dut (
    input  clk, rst_n, wr_en, rd_en, wdata,
    output rdata, full, empty, count
  );

endinterface
