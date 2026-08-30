# examples

This lab's runnable content lives under `rtl/`, `tb/verilator/`, and
`tb/uvm/`. This folder only maps directed CI tests to UVM sequences so an
interview discussion can jump from "what CI ran" to "what the class TB
would have run".

| Verilator test (`tb/verilator/tb_top.sv`) | UVM sequence / test |
| --- | --- |
| `test_reset_flags` | reset in `tb/uvm/tb_top.sv` + first item after `rst_n` |
| `test_fill_exact_depth` | `fifo_fill_seq` / `fifo_fill_empty_test` |
| `test_overflow_ignored` | fill then an extra write (`fifo_fill_seq` + one `wr` item) |
| `test_drain_exact` | `fifo_drain_seq` |
| `test_simultaneous` | `fifo_simultaneous_seq` |
| `test_random_traffic` | `fifo_smoke_seq` (`$urandom` / `randomize()`, never `$random`) |
| `test_apb_walk` | `apb_mem_walk_seq` / `apb_mem_test` |
| `test_apb_slverr_no_corrupt` | `apb_slverr_seq` |

UVM compile is **not** CI. See `tb/uvm/filelist.f` and `examples/run_uvm.example.sh`.
