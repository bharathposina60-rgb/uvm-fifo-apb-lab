// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
//
// file: rtl/apb_slave.sv
// Simple APB3-style slave with a small word-addressable memory.
// Public-safe teaching RTL. Not ARM VIP. Not a product register map.
//
// Assumptions:
//   - APB3: SETUP (PSEL && !PENABLE) then ACCESS (PSEL && PENABLE).
//   - Zero wait states: PREADY is tied 1. Master still must drive SETUP+ACCESS.
//   - Byte addresses, 32-bit words, word-aligned. PADDR[1:0] ignored.
//   - Legal map: MEM_WORDS words starting at address 0.
//     For MEM_WORDS=16, word index is PADDR[5:2]; PADDR[ADDR_WIDTH-1:6] must be 0.
//   - Out-of-range ACCESS asserts PSLVERR and does not write.
//   - PRDATA is combinational from the indexed word (valid in ACCESS).
//   - Memory is cleared on PRESETn so read-before-write is defined in sim.
//
`timescale 1ns/1ps

module apb_slave #(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 32,
  parameter int MEM_WORDS  = 16
) (
  input  logic                     PCLK,
  input  logic                     PRESETn,
  input  logic                     PSEL,
  input  logic                     PENABLE,
  input  logic                     PWRITE,
  input  logic [ADDR_WIDTH-1:0]    PADDR,
  input  logic [DATA_WIDTH-1:0]    PWDATA,
  output logic [DATA_WIDTH-1:0]    PRDATA,
  output logic                     PREADY,
  output logic                     PSLVERR
);

  localparam int WORD_IDX_W = $clog2(MEM_WORDS);
  localparam int IDX_LO     = 2;
  localparam int IDX_HI     = 2 + WORD_IDX_W - 1;

  logic [DATA_WIDTH-1:0]          mem [0:MEM_WORDS-1];
  logic [WORD_IDX_W-1:0]          word_idx;
  logic                           access;
  logic                           addr_err;

  assign word_idx = PADDR[IDX_HI:IDX_LO];
  assign access   = PSEL && PENABLE;

  // Bits above the legal word map are an error. LSBs [1:0] are ignored.
  assign addr_err = access && (|PADDR[ADDR_WIDTH-1:IDX_HI+1]);

  assign PREADY  = 1'b1;
  assign PSLVERR = addr_err;
  assign PRDATA  = mem[word_idx];

  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      mem <= '{default: '0};
    end else if (access && PWRITE && PREADY && !addr_err) begin
      mem[word_idx] <= PWDATA;
    end
  end

`ifndef SYNTHESIS
  initial begin
    if (MEM_WORDS < 1)
      $error("apb_slave: MEM_WORDS must be >= 1");
    if (ADDR_WIDTH < (IDX_HI + 2))
      $error("apb_slave: ADDR_WIDTH=%0d is too small for MEM_WORDS=%0d",
             ADDR_WIDTH, MEM_WORDS);
    if (DATA_WIDTH != 32)
      $error("apb_slave: teaching slave is 32-bit (got DATA_WIDTH=%0d)", DATA_WIDTH);
  end
`endif

endmodule
