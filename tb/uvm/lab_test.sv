// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/lab_test.sv
// Objections live here (and in virtual sequences), never in drivers.
// Drain time covers the last registered FIFO rdata beat.

class lab_base_test extends uvm_test;
  `uvm_component_utils(lab_base_test)

  lab_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = lab_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
endclass

class fifo_fill_empty_test extends lab_base_test;
  `uvm_component_utils(fifo_fill_empty_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    fifo_fill_empty_seq seq;
    phase.raise_objection(this);
    seq = fifo_fill_empty_seq::type_id::create("seq");
    seq.start(env.fifo_ag.sequencer);
    phase.phase_done.set_drain_time(this, 100);
    phase.drop_objection(this);
  endtask
endclass

class apb_mem_test extends lab_base_test;
  `uvm_component_utils(apb_mem_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    apb_mem_test_seq seq;
    phase.raise_objection(this);
    seq = apb_mem_test_seq::type_id::create("seq");
    seq.start(env.apb_ag.sequencer);
    phase.phase_done.set_drain_time(this, 100);
    phase.drop_objection(this);
  endtask
endclass

class lab_smoke_test extends lab_base_test;
  `uvm_component_utils(lab_smoke_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    fifo_fill_empty_seq fifo_seq;
    apb_mem_test_seq    apb_seq;
    phase.raise_objection(this);
    fifo_seq = fifo_fill_empty_seq::type_id::create("fifo_seq");
    apb_seq  = apb_mem_test_seq::type_id::create("apb_seq");
    fork
      fifo_seq.start(env.fifo_ag.sequencer);
      apb_seq.start(env.apb_ag.sequencer);
    join
    phase.phase_done.set_drain_time(this, 100);
    phase.drop_objection(this);
  endtask
endclass
