// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
//
// file: rtl/sync_fifo.sv
// Generic synchronous FIFO (IEEE 1800). Public-safe teaching RTL.
//
// Assumptions:
//   - Single clock domain. No CDC.
//   - Active-low rst_n. Pointers, count, flags, and rdata reset; RAM does not.
//   - DEPTH >= 2. Need not be a power of two.
//   - Writes while full are ignored. Reads while empty are ignored.
//   - Simultaneous wr+rd when neither full nor empty: occupancy unchanged.
//   - rdata is registered (not first-word fall-through). After a successful
//     read, rdata is the popped word and is stable until the next read.
//   - Never use $random in RTL.
//
`timescale 1ns/1ps

module sync_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16
) (
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         wr_en,
  input  logic                         rd_en,
  input  logic [WIDTH-1:0]             wdata,
  output logic [WIDTH-1:0]             rdata,
  output logic                         full,
  output logic                         empty,
  output logic [$clog2(DEPTH+1)-1:0]   count
);

  localparam int ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
  localparam int CNT_W  = $clog2(DEPTH + 1);

  logic [WIDTH-1:0]  mem [0:DEPTH-1];
  logic [ADDR_W-1:0] wr_ptr;
  logic [ADDR_W-1:0] rd_ptr;

  wire do_wr = wr_en && !full;
  wire do_rd = rd_en && !empty;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;
      rdata  <= '0;
    end else begin
      if (do_wr) begin
        mem[wr_ptr] <= wdata;
        wr_ptr <= (wr_ptr == ADDR_W'(DEPTH - 1)) ? '0 : (wr_ptr + 1'b1);
      end
      if (do_rd) begin
        rdata  <= mem[rd_ptr];
        rd_ptr <= (rd_ptr == ADDR_W'(DEPTH - 1)) ? '0 : (rd_ptr + 1'b1);
      end
      case ({do_wr, do_rd})
        2'b10:   count <= count + 1'b1;
        2'b01:   count <= count - 1'b1;
        default: ; // idle or simultaneous: occupancy unchanged
      endcase
    end
  end

  // full is count == DEPTH, NOT DEPTH-1.
  //
  // BUG FOUND+FIXED (see docs/debug-note.md):
  //   An earlier revision used `assign full = (count == DEPTH-1);` which
  //   advertised full one slot early and dropped the last legal write.
  //   tb/verilator/tb_top.sv::test_fill_exact_depth caught it: after 15
  //   writes full was already 1, the 16th write was ignored, and a 16-beat
  //   drain went empty after 15 reads.
  //   Do not "simplify" this comparison back to DEPTH-1.
  assign full  = (count == CNT_W'(DEPTH));
  assign empty = (count == '0);

`ifndef SYNTHESIS
  initial begin
    if (DEPTH < 2)
      $error("sync_fifo: DEPTH must be >= 2 (got %0d)", DEPTH);
  end
`endif

endmodule
