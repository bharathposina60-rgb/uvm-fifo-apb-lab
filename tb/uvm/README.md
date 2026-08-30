# tb/uvm — interview artifact

This tree is a **UVM 1.2-shaped** class testbench for the same DUT that
`tb/verilator` simulates in CI.

It is **not** compiled by `make sim`. Accellera UVM does not run well under
Verilator. To compile this tree you need:

1. A UVM 1.2 library (`uvm_pkg`, `uvm_macros.svh`)
2. A commercial or UVM-compatible simulator (VCS, Xcelium, Questa, …)

```
+UVM_TESTNAME=lab_smoke_test
+UVM_TESTNAME=fifo_fill_empty_test
+UVM_TESTNAME=apb_mem_test
+ntb_random_seed=<int>
```

See `filelist.f` for a VCS-shaped command line.

## How this maps to UVM 1.2

| UVM 1.2 class | FIFO | APB |
| --- | --- | --- |
| `uvm_sequence_item` | `fifo_item` | `apb_item` |
| `uvm_sequencer #(REQ)` | `fifo_sequencer` | `apb_sequencer` |
| `uvm_driver #(REQ)` | `fifo_driver` | `apb_driver` |
| `uvm_monitor` | `fifo_monitor` | `apb_monitor` |
| `uvm_agent` (`is_active`) | `fifo_agent` | `apb_agent` |
| `uvm_scoreboard` | `fifo_scoreboard` | `apb_scoreboard` |
| `uvm_subscriber` + covergroup | `fifo_coverage` | `apb_coverage` |
| `uvm_env` | `lab_env` | same |
| `uvm_test` | `lab_smoke_test` | `apb_mem_test` |

Factory: `uvm_object_utils` / `uvm_component_utils` and `type_id::create`.
Virtual interfaces travel through `uvm_config_db`. Drivers do
`get_next_item` → drive → `item_done` and **do not** raise objections.
Tests raise/drop objections and set drain time.

`import uvm_pkg::*;` is gated by `` `ifdef UVM `` so a stray compile does
not pull class syntax into Verilator.
