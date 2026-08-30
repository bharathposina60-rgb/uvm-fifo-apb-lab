#!/usr/bin/env bash
# Example only. Not used by CI. Needs UVM 1.2 + a commercial / compatible sim.
# Adjust the simulator invocation for Xcelium / Questa as needed.
set -euo pipefail

# vcs -sverilog -full64 -timescale=1ns/1ps -ntb_opts uvm-1.2 \
#     -f tb/uvm/filelist.f -o simv
# ./simv +UVM_TESTNAME=lab_smoke_test +ntb_random_seed=1

echo "This script is a comment block. See tb/uvm/README.md" >&2
exit 1
