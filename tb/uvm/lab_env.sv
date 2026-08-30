// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Bharath Posina
// file: tb/uvm/lab_env.sv
// Scoreboards and coverage subscribe to analysis ports. They do not poke the DUT.

class lab_env extends uvm_env;
  `uvm_component_utils(lab_env)

  fifo_agent      fifo_ag;
  apb_agent       apb_ag;
  fifo_scoreboard fifo_sb;
  apb_scoreboard  apb_sb;
  fifo_coverage   fifo_cov;
  apb_coverage    apb_cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    fifo_ag  = fifo_agent::type_id::create("fifo_ag", this);
    apb_ag   = apb_agent::type_id::create("apb_ag", this);
    fifo_sb  = fifo_scoreboard::type_id::create("fifo_sb", this);
    apb_sb   = apb_scoreboard::type_id::create("apb_sb", this);
    fifo_cov = fifo_coverage::type_id::create("fifo_cov", this);
    apb_cov  = apb_coverage::type_id::create("apb_cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    fifo_ag.monitor.ap.connect(fifo_sb.imp);
    fifo_ag.monitor.ap.connect(fifo_cov.analysis_export);
    apb_ag.monitor.ap.connect(apb_sb.imp);
    apb_ag.monitor.ap.connect(apb_cov.analysis_export);
  endfunction
endclass
