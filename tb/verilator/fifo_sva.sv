// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
//
// file: tb/verilator/fifo_sva.sv
// Bind-ready FIFO checkers. Concurrent SVA always uses disable iff.
// These assertions would have fired on the DEPTH-1 full-flag bug.
//
`timescale 1ns/1ps

module fifo_sva #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16
) (
  input logic                       clk,
  input logic                       rst_n,
  input logic                       wr_en,
  input logic                       rd_en,
  input logic [WIDTH-1:0]           wdata,
  input logic [WIDTH-1:0]           rdata,
  input logic                       full,
  input logic                       empty,
  input logic [$clog2(DEPTH+1)-1:0] count
);

  // Mutual exclusion of full and empty for DEPTH >= 1.
  property p_not_full_and_empty;
    @(posedge clk) disable iff (!rst_n)
      !(full && empty);
  endproperty
  a_not_full_and_empty: assert property (p_not_full_and_empty)
    else $error("FIFO full && empty at count=%0d", count);
  c_not_full_and_empty: cover property (p_not_full_and_empty);

  property p_full_means_depth;
    @(posedge clk) disable iff (!rst_n)
      full |-> (count == DEPTH);
  endproperty
  a_full_means_depth: assert property (p_full_means_depth)
    else $error("full=1 but count=%0d DEPTH=%0d (off-by-one?)", count, DEPTH);

  property p_empty_means_zero;
    @(posedge clk) disable iff (!rst_n)
      empty |-> (count == '0);
  endproperty
  a_empty_means_zero: assert property (p_empty_means_zero)
    else $error("empty=1 but count=%0d", count);

  property p_count_in_range;
    @(posedge clk) disable iff (!rst_n)
      count <= DEPTH;
  endproperty
  a_count_in_range: assert property (p_count_in_range);

  // Legal occupancy-changing ops.
  property p_write_accepted;
    @(posedge clk) disable iff (!rst_n)
      wr_en && !full;
  endproperty
  c_write_accepted: cover property (p_write_accepted);

  property p_read_accepted;
    @(posedge clk) disable iff (!rst_n)
      rd_en && !empty;
  endproperty
  c_read_accepted: cover property (p_read_accepted);

  property p_simultaneous;
    @(posedge clk) disable iff (!rst_n)
      wr_en && rd_en && !full && !empty;
  endproperty
  c_simultaneous: cover property (p_simultaneous);

  property p_write_when_full;
    @(posedge clk) disable iff (!rst_n)
      wr_en && full && !rd_en;
  endproperty
  c_write_when_full: cover property (p_write_when_full);

  property p_read_when_empty;
    @(posedge clk) disable iff (!rst_n)
      rd_en && empty && !wr_en;
  endproperty
  c_read_when_empty: cover property (p_read_when_empty);

endmodule
