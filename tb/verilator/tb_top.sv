// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
//
// file: tb/verilator/tb_top.sv
// Directed / constrained-lite self-checking TB for Verilator.
// Instantiates the same DUT as the UVM tree. No uvm_pkg.
//
// Checks:
//   - reset leaves FIFO empty / not full
//   - fill exactly DEPTH (catches the full-flag off-by-one)
//   - extra write while full is ignored
//   - drain exactly DEPTH, extra read while empty is ignored
//   - simultaneous wr+rd mid-occupancy
//   - random legal traffic vs a queue model ($urandom, not $random)
//   - APB write/read match across the 16-word map
//   - APB out-of-range ACCESS sets PSLVERR and does not corrupt the map
//
// Seed: +seed=<int>. Default 1. Printed at start for debug-note.md step 4.
//
`timescale 1ns/1ps

module tb_top;

  localparam int WIDTH     = 8;
  localparam int DEPTH     = 16;
  localparam int ADDR_W    = 8;
  localparam int DATA_W    = 32;
  localparam int MEM_WORDS = 16;

  logic                  clk;
  logic                  rst_n;

  logic                  wr_en;
  logic                  rd_en;
  logic [WIDTH-1:0]      wdata;
  logic [WIDTH-1:0]      rdata;
  logic                  full;
  logic                  empty;
  logic [$clog2(DEPTH+1)-1:0] count;

  logic                  PSEL;
  logic                  PENABLE;
  logic                  PWRITE;
  logic [ADDR_W-1:0]     PADDR;
  logic [DATA_W-1:0]     PWDATA;
  logic [DATA_W-1:0]     PRDATA;
  logic                  PREADY;
  logic                  PSLVERR;

  int unsigned           seed;
  int                    errors;
  int                    checks;

  // Queue model for random FIFO traffic. $urandom only.
  logic [WIDTH-1:0]      model [$];

  // ------------------------------------------------------------------ DUT
  sync_fifo #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) u_fifo (
    .clk   (clk),
    .rst_n (rst_n),
    .wr_en (wr_en),
    .rd_en (rd_en),
    .wdata (wdata),
    .rdata (rdata),
    .full  (full),
    .empty (empty),
    .count (count)
  );

  apb_slave #(
    .ADDR_WIDTH(ADDR_W),
    .DATA_WIDTH(DATA_W),
    .MEM_WORDS (MEM_WORDS)
  ) u_apb (
    .PCLK   (clk),
    .PRESETn(rst_n),
    .PSEL   (PSEL),
    .PENABLE(PENABLE),
    .PWRITE (PWRITE),
    .PADDR  (PADDR),
    .PWDATA (PWDATA),
    .PRDATA (PRDATA),
    .PREADY (PREADY),
    .PSLVERR(PSLVERR)
  );

  bind u_fifo fifo_sva #(.WIDTH(WIDTH), .DEPTH(DEPTH)) u_fifo_sva (.*);
  bind u_apb  apb_sva  #(.ADDR_WIDTH(ADDR_W), .DATA_WIDTH(DATA_W)) u_apb_sva (.*);

  // ------------------------------------------------------------------ clock
  initial clk = 1'b0;
  // Blocking toggle is the usual TB clock; not synthesizable sequential logic.
  /* verilator lint_off BLKSEQ */
  always #5 clk = ~clk;
  /* verilator lint_on BLKSEQ */

  // ------------------------------------------------------------------ helpers
  task automatic check(input bit cond, input string msg);
    checks++;
    if (!cond) begin
      errors++;
      $error("FAIL t=%0t: %s", $time, msg);
    end
  endtask

  task automatic apply_reset();
    rst_n   = 1'b0;
    wr_en   = 1'b0;
    rd_en   = 1'b0;
    wdata   = '0;
    PSEL    = 1'b0;
    PENABLE = 1'b0;
    PWRITE  = 1'b0;
    PADDR   = '0;
    PWDATA  = '0;
    model.delete();
    repeat (4) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    @(negedge clk);
  endtask

  // Drive on negedge so the next posedge is a clean capture.
  task automatic fifo_write(input logic [WIDTH-1:0] d);
    @(negedge clk);
    wr_en = 1'b1;
    rd_en = 1'b0;
    wdata = d;
    @(posedge clk);
    @(negedge clk);
    wr_en = 1'b0;
  endtask

  task automatic fifo_read();
    @(negedge clk);
    wr_en = 1'b0;
    rd_en = 1'b1;
    @(posedge clk);
    @(negedge clk);
    rd_en = 1'b0;
  endtask

  task automatic fifo_both(input logic [WIDTH-1:0] d);
    @(negedge clk);
    wr_en = 1'b1;
    rd_en = 1'b1;
    wdata = d;
    @(posedge clk);
    @(negedge clk);
    wr_en = 1'b0;
    rd_en = 1'b0;
  endtask

  task automatic fifo_idle();
    @(negedge clk);
    wr_en = 1'b0;
    rd_en = 1'b0;
    @(posedge clk);
    @(negedge clk);
  endtask

  // APB3 SETUP then ACCESS. Sample PRDATA/PSLVERR on the ready posedge.
  task automatic apb_xfer(
    input  bit               write,
    input  logic [ADDR_W-1:0] addr,
    input  logic [DATA_W-1:0] wdat,
    output logic [DATA_W-1:0] rdat,
    output logic              slverr
  );
    @(negedge clk);
    PSEL    = 1'b1;
    PENABLE = 1'b0;
    PWRITE  = write;
    PADDR   = addr;
    PWDATA  = wdat;
    @(negedge clk);
    PENABLE = 1'b1;
    @(posedge clk);
    // 0-wait slave keeps PREADY high; loop is for APB3 shape / future wait-states.
    while (!PREADY) @(posedge clk);
    rdat   = PRDATA;
    slverr = PSLVERR;
    @(negedge clk);
    PSEL    = 1'b0;
    PENABLE = 1'b0;
    PWRITE  = 1'b0;
  endtask

  // ------------------------------------------------------------------ tests
  task automatic test_reset_flags();
    $display("TEST reset_flags");
    apply_reset();
    check(empty === 1'b1, "empty after reset");
    check(full  === 1'b0, "not full after reset");
    check(count === '0,   "count==0 after reset");
  endtask

  // This is the test that caught the DEPTH-1 full-flag bug.
  task automatic test_fill_exact_depth();
    int i;
    $display("TEST fill_exact_depth (off-by-one killer)");
    apply_reset();
    for (i = 0; i < DEPTH; i++) begin
      check(full === 1'b0, $sformatf("not full before write %0d", i));
      check(int'(count) == i,    $sformatf("count==%0d before write %0d", i, i));
      fifo_write(WIDTH'(8'hA0 + i));
      check(empty === 1'b0, $sformatf("not empty after write %0d", i));
    end
    check(full  === 1'b1, "full after DEPTH writes");
    check(int'(count) == DEPTH, "count==DEPTH after fill");
  endtask

  task automatic test_overflow_ignored();
    logic [WIDTH-1:0] got;
    $display("TEST overflow_ignored");
    // FIFO is full from previous test. Extra write must not displace 8'hA0.
    fifo_write(8'hFF);
    check(full === 1'b1, "still full after ignored overflow write");
    check(int'(count) == DEPTH, "count still DEPTH after overflow write");
    fifo_read();
    got = rdata;
    check(got === 8'hA0, $sformatf("head after overflow write must be 0xA0, got 0x%02x", got));
  endtask

  task automatic test_drain_exact();
    int i;
    logic [WIDTH-1:0] got;
    logic [WIDTH-1:0] exp;
    $display("TEST drain_exact");
    // One word already popped in overflow test; 15 remain (0xA1..0xAF).
    for (i = 1; i < DEPTH; i++) begin
      check(empty === 1'b0, $sformatf("not empty before read %0d", i));
      fifo_read();
      got = rdata;
      exp = WIDTH'(8'hA0 + i);
      check(got === exp, $sformatf("rdata exp 0x%02x got 0x%02x", exp, got));
    end
    check(empty === 1'b1, "empty after draining the remaining items");
    check(full  === 1'b0, "not full when empty");
    check(count === '0,   "count==0 after drain");
  endtask

  task automatic test_underflow_ignored();
    logic [WIDTH-1:0] prev_r, post_r;
    $display("TEST underflow_ignored");
    prev_r = rdata;
    fifo_read();
    post_r = rdata;
    check(empty === 1'b1, "still empty after ignored underflow read");
    check(post_r === prev_r, "rdata unchanged on underflow read");
    check(count === '0, "count still 0 after underflow read");
  endtask

  task automatic test_simultaneous();
    int i;
    logic [WIDTH-1:0] got;
    $display("TEST simultaneous mid-occupancy");
    apply_reset();
    for (i = 0; i < 8; i++)
      fifo_write(WIDTH'(i));
    check(int'(count) == 8, "half full before simultaneous");

    for (i = 0; i < 8; i++) begin
      fifo_both(WIDTH'(8 + i));
      got = rdata;
      check(got === WIDTH'(i), $sformatf("simultaneous read exp %0d got %0d", i, got));
      check(int'(count) == 8, "occupancy unchanged during simultaneous");
      check(full === 1'b0 && empty === 1'b0, "neither flag during mid simultaneous");
    end

    for (i = 0; i < 8; i++) begin
      fifo_read();
      got = rdata;
      check(got === WIDTH'(8 + i), $sformatf("drain after sim exp %0d got %0d", 8 + i, got));
    end
    check(empty === 1'b1, "empty after simultaneous drain");
  endtask

  task automatic test_random_traffic();
    int i;
    bit do_wr, do_rd;
    logic [WIDTH-1:0] din;
    logic [WIDTH-1:0] exp;
    $display("TEST random_traffic seed=%0d", seed);
    apply_reset();
    for (i = 0; i < 80; i++) begin
      do_wr = ($urandom_range(0, 1) != 0);
      do_rd = ($urandom_range(0, 1) != 0);
      din   = WIDTH'($urandom_range(0, 255));

      // Keep the model in lock-step with DUT accept rules.
      if (do_wr && do_rd && !full && !empty) begin
        fifo_both(din);
        exp = model.pop_front();
        check(rdata === exp, $sformatf("rand both rdata exp 0x%02x got 0x%02x", exp, rdata));
        model.push_back(din);
      end else if (do_wr && !do_rd) begin
        fifo_write(din);
        if (model.size() < DEPTH)
          model.push_back(din);
      end else if (do_rd && !do_wr) begin
        fifo_read();
        if (model.size() > 0) begin
          exp = model.pop_front();
          check(rdata === exp, $sformatf("rand read rdata exp 0x%02x got 0x%02x", exp, rdata));
        end
      end else begin
        fifo_idle();
      end

      check(int'(count) == model.size(),
            $sformatf("rand count DUT=%0d model=%0d", count, model.size()));
      check(empty === (model.size() == 0), "rand empty vs model");
      check(full  === (model.size() == DEPTH), "rand full vs model");
    end
  endtask

  task automatic test_apb_walk();
    int i;
    logic [DATA_W-1:0] rdat;
    logic              slverr;
    logic [DATA_W-1:0] exp;
    logic [ADDR_W-1:0] addr;
    $display("TEST apb_walk");
    apply_reset();
    for (i = 0; i < MEM_WORDS; i++) begin
      addr = ADDR_W'(i << 2);
      exp  = DATA_W'(32'hA5A50000 + i);
      apb_xfer(1'b1, addr, exp, rdat, slverr);
      check(slverr === 1'b0, $sformatf("APB write word %0d slverr", i));
    end
    for (i = 0; i < MEM_WORDS; i++) begin
      addr = ADDR_W'(i << 2);
      exp  = DATA_W'(32'hA5A50000 + i);
      apb_xfer(1'b0, addr, 32'h0, rdat, slverr);
      check(slverr === 1'b0, $sformatf("APB read word %0d slverr", i));
      check(rdat === exp, $sformatf("APB read word %0d exp 0x%08x got 0x%08x", i, exp, rdat));
    end
  endtask

  task automatic test_apb_slverr_no_corrupt();
    logic [DATA_W-1:0] rdat, orig;
    logic              slverr;
    $display("TEST apb_slverr_no_corrupt");
    // Word 0 holds 0xA5A50000 from the walk. Out-of-range 0x40 must slverr
    // and must not change word 0.
    apb_xfer(1'b0, 8'h00, 32'h0, orig, slverr);
    check(slverr === 1'b0, "word0 still readable");
    apb_xfer(1'b1, 8'h40, 32'hDEADBEEF, rdat, slverr);
    check(slverr === 1'b1, "write 0x40 must slverr");
    apb_xfer(1'b0, 8'h40, 32'h0, rdat, slverr);
    check(slverr === 1'b1, "read 0x40 must slverr");
    apb_xfer(1'b0, 8'h00, 32'h0, rdat, slverr);
    check(slverr === 1'b0, "word0 still in map");
    check(rdat === orig, $sformatf("word0 unchanged after oob write, got 0x%08x", rdat));
  endtask

  // ------------------------------------------------------------------ main
  initial begin
    errors = 0;
    checks = 0;
    if (!$value$plusargs("seed=%d", seed))
      seed = 32'd1;
    void'($urandom(seed));
    $display("====================================================");
    $display(" uvm-fifo-apb-lab  Verilator TB  SEED=%0d", seed);
    $display("====================================================");

    test_reset_flags();
    test_fill_exact_depth();
    test_overflow_ignored();
    test_drain_exact();
    test_underflow_ignored();
    test_simultaneous();
    test_random_traffic();
    test_apb_walk();
    test_apb_slverr_no_corrupt();

    $display("====================================================");
    if (errors != 0) begin
      $fatal(1, "FAIL  %0d errors / %0d checks  SEED=%0d", errors, checks, seed);
    end else begin
      $display("PASS  %0d checks  SEED=%0d", checks, seed);
      $finish;
    end
  end

  // Watchdog: a hung clock / forgotten $finish must fail CI.
  initial begin
    #200000;
    $fatal(1, "watchdog timeout — clock, reset, or a task is stuck");
  end

  initial begin
    if ($test$plusargs("trace")) begin
      $dumpfile("waves.vcd");
      $dumpvars(0, tb_top);
    end
  end

endmodule
