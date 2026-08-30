// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
//
// file: tb/verilator/apb_sva.sv
// Bind-ready APB3-style checkers. Concurrent SVA always uses disable iff.
//
`timescale 1ns/1ps

module apb_sva #(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 32
) (
  input logic                     PCLK,
  input logic                     PRESETn,
  input logic                     PSEL,
  input logic                     PENABLE,
  input logic                     PWRITE,
  input logic [ADDR_WIDTH-1:0]    PADDR,
  input logic [DATA_WIDTH-1:0]    PWDATA,
  input logic [DATA_WIDTH-1:0]    PRDATA,
  input logic                     PREADY,
  input logic                     PSLVERR
);

  property p_enable_implies_sel;
    @(posedge PCLK) disable iff (!PRESETn)
      PENABLE |-> PSEL;
  endproperty
  a_enable_implies_sel: assert property (p_enable_implies_sel)
    else $error("PENABLE without PSEL (broken APB handshake)");

  property p_setup_then_access;
    @(posedge PCLK) disable iff (!PRESETn)
      (PSEL && !PENABLE) |=> (PSEL && PENABLE);
  endproperty
  a_setup_then_access: assert property (p_setup_then_access)
    else $error("APB SETUP cycle not followed by ACCESS");
  c_setup_then_access: cover property (p_setup_then_access);

  property p_slverr_only_in_access;
    @(posedge PCLK) disable iff (!PRESETn)
      PSLVERR |-> (PSEL && PENABLE);
  endproperty
  a_slverr_only_in_access: assert property (p_slverr_only_in_access);

  property p_write_access;
    @(posedge PCLK) disable iff (!PRESETn)
      PSEL && PENABLE && PWRITE && PREADY && !PSLVERR;
  endproperty
  c_write_access: cover property (p_write_access);

  property p_read_access;
    @(posedge PCLK) disable iff (!PRESETn)
      PSEL && PENABLE && !PWRITE && PREADY && !PSLVERR;
  endproperty
  c_read_access: cover property (p_read_access);

  property p_slverr_access;
    @(posedge PCLK) disable iff (!PRESETn)
      PSEL && PENABLE && PREADY && PSLVERR;
  endproperty
  c_slverr_access: cover property (p_slverr_access);

endmodule
