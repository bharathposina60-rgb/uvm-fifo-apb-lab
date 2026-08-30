// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
//
// file: rtl/apb_if.sv
// Public APB3-style slave signals (IEEE 1800). Not ARM VIP.
// Clocking blocks are omitted under Verilator; the CI TB drives DUT ports.
//
`timescale 1ns/1ps

interface apb_if #(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 32
) (
  input logic PCLK,
  input logic PRESETn
);

  logic                     PSEL;
  logic                     PENABLE;
  logic                     PWRITE;
  logic [ADDR_WIDTH-1:0]    PADDR;
  logic [DATA_WIDTH-1:0]    PWDATA;
  logic [DATA_WIDTH-1:0]    PRDATA;
  logic                     PREADY;
  logic                     PSLVERR;

`ifndef VERILATOR
  clocking drv_cb @(posedge PCLK);
    default input #1step output #0;
    output PSEL, PENABLE, PWRITE, PADDR, PWDATA;
    input  PRDATA, PREADY, PSLVERR;
  endclocking

  clocking mon_cb @(posedge PCLK);
    default input #1step;
    input PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY, PSLVERR, PRESETn;
  endclocking

  modport drv (clocking drv_cb, input PCLK, PRESETn);
  modport mon (clocking mon_cb, input PCLK, PRESETn);
`endif

  modport slv (
    input  PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA,
    output PRDATA, PREADY, PSLVERR
  );

endinterface
