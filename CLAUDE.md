# uvm-fifo-apb-lab conventions

Public-safe ASIC DV teaching lab. Same rules as
[claude-dv-kit](https://github.com/bharathposina60-rgb/claude-dv-kit).

- IEEE 1800 SystemVerilog. Prefer `logic`, `always_ff` / `always_comb`,
  `interface` + `modport`, concurrent SVA, covergroups.
- UVM 1.2 shapes in `tb/uvm/`. Verilator cannot run Accellera UVM well;
  keep that tree behind `ifdef UVM` and do not add it to `make sim`.
- Never `$random`. Use `$urandom`, `$urandom_range`, or `std::randomize()`
  with constraints. Seed from plusargs (`+seed=`, `+ntb_random_seed`).
- Named cover bins only. No implicit `bins others` as the sole closure of a
  hole. Coverpoints `cp_*`, bins `bin_*`.
- Every concurrent `property` / `assert property` / `assume property` /
  `cover property` needs `disable iff` tied to `!rst_n` or `!PRESETn`, and
  an explicit `@(posedge clk)` / `@(posedge PCLK)`.
- Bind SVA (`tb/verilator/*_sva.sv`). Do not edit DUT internals to insert
  checks.
- No proprietary IP: no Micron, NAND, UFS, product register maps, vendor
  VIP, unsanitized logs. Textbook FIFO and APB3-style names and widths only.
- Reset: `rst_n` / `PRESETn` active-low. Parameters: `WIDTH`, `DEPTH`,
  `ADDR_WIDTH` in SCREAMING_SNAKE.
- Objections only in tests / virtual sequences, never in drivers.
- Debug order unless the log already disproves a step: clocks, reset,
  objections/drain, seed. See `docs/debug-note.md`.
