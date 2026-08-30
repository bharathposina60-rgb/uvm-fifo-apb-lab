# Debug note: FIFO `full` off-by-one

This is a real bug that lived in `rtl/sync_fifo.sv` during bring-up of the
Verilator TB, then was fixed. The old comparison is still named in a comment
on the `assign full` line so it cannot be "simplified" back in.

## Injected / found bug

```systemverilog
assign full = (count == DEPTH - 1);   // WRONG
```

People write this when they think of "one slot left" as full. For
`DEPTH=16` the DUT then advertised `full` at occupancy 15, dropped the 16th
write, and had only 15 words to drain.

Correct:

```systemverilog
assign full = (count == CNT_W'(DEPTH));
```

## Symptom

`test_fill_exact_depth` in `tb/verilator/tb_top.sv` failed on the 16th write
(index 15). Re-injecting `count == DEPTH-1` under Verilator 5.032 produced:

```
TEST fill_exact_depth (off-by-one killer)
FAIL t=400000: not full before write 15
%Error: Verilog $stop
make: *** [Makefile:56: sim] Aborted
```

Verilator treats `$error` as a stop, so CI exits non-zero on the first
mismatch. The same cycle is when `full` has already gone high at occupancy
15. SVA `a_full_means_depth` (`full |-> count == DEPTH`) is the cycle-level
form of that check.

A 16-beat drain would then see `empty` after 15 reads, and the software
queue model in `test_random_traffic` would diverge as soon as occupancy
tried to reach 16. We never got that far: the directed fill test died first.

The failure was **directed**, not seed-dependent.

## Debug order (clocks → reset → objections/drain → seed)

Worked this order; nothing above the RTL comparison was at fault.

1. **Clocks.** `always #5 clk = ~clk` under Verilator `--timing`. VCD
   (`make waves`) showed a 10 ns period on `tb_top.clk` for the whole run.
   Both DUTs share that clock. Not a clock issue.
2. **Reset.** `apply_reset` holds `rst_n` low for 4 posedges, releases on
   negedge, then waits one more posedge. After release: `empty=1`,
   `full=0`, `count=0`. No X on `rst_n`. Reset path was fine.
3. **Objections / drain.** N/A on the Verilator path (no UVM phasing). On
   the UVM path the equivalent hang would be an undropped
   `raise_objection` or a drain time too short for registered `rdata`;
   tests use `phase.phase_done.set_drain_time(this, 100)` and drivers never
   raise. This fail was a mismatch, not a hang, so objections were not
   suspects.
4. **Seed.** Log line `SEED=1`. Re-ran `make sim PLUSARGS=+seed=1` and
   `PLUSARGS=+seed=7`; fill/drain failures were identical. Random traffic
   failed later for the same occupancy reason. Capturing the seed still
   mattered: it proved the fail was not a `$urandom` artifact.

Only then: stare at `assign full`. `count==DEPTH-1` matched every symptom.

## How it was caught

Not by eyeballing RTL. The directed test writes `DEPTH` unique values
`8'hA0+i` and asserts:

- `!full` **before** every write, including write 15
- `full && count==DEPTH` **after** write 15
- an extra `8'hFF` write must not displace the head (`rdata` after the
  first pop is still `8'hA0`)

That is the test you want in a FIFO scoreboard / vplan row for "capacity
is DEPTH, not DEPTH-1". The SVA `p_full_means_depth` is the same check on
every clock.

## What we did not do

- Did not "fix" it in the TB by writing only 15 beats.
- Did not mask SVA with `$assertoff`.
- Did not blame Verilator `--timing` once the clock was toggling.

## Residual risk

If someone removes `count` from the DUT, keep a TB-side occupancy counter;
the directed fill/drain checks do not need the DUT `count` port, but the
SVA `p_full_means_depth` does.
