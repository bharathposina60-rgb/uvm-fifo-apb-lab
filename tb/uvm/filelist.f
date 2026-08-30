# UVM 1.2 compile list. Not used by `make sim`.
# Example (VCS):
#   vcs -sverilog -full64 -timescale=1ns/1ps -ntb_opts uvm-1.2 \
#       -f tb/uvm/filelist.f -o simv
#   ./simv +UVM_TESTNAME=lab_smoke_test +ntb_random_seed=1
#
+incdir+rtl
+incdir+tb/uvm
+define+UVM
rtl/fifo_if.sv
rtl/apb_if.sv
rtl/sync_fifo.sv
rtl/apb_slave.sv
tb/uvm/lab_pkg.sv
tb/uvm/tb_top.sv
