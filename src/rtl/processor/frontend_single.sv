// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


`include "workarounds.svh"

module Frontend_single
  #(parameter int OPT_BCACHE = 0,
    parameter int OPT_IF_LATENCY = 1,
    parameter Pu_types::Opt_mem OPT_DMEM = Pu_types::MEM_TIGHT,
    parameter bit OPT_BCACHE_IGNORES_JUMPS = 1'b0,
    parameter bit OPT_BUFFER_BCTRL = 1'b0,
    parameter bit OPT_WRITE_THROUGH = 1'b1,
    parameter bit OPT_LOOKUP_CACHE = 1'b1)
  ( input logic clk, reset, ext_hold,
    
    Ram_if.client                          imem,

    Int_sched_if.frontend                  int_sched,

    //Register_file_if.inst_fetch  reg_file,
    Wb_channel_if.ctrl                     wb_gpr,
    Wb_channel_if.ctrl                     wb_cr,
    Wb_channel_if.ctrl                     wb_ctr,
    Wb_channel_if.ctrl                     wb_lnk,
    Wb_channel_if.ctrl                     wb_xer,
    Wb_channel_if.ctrl                     wb_spr,
    Wb_channel_if.ctrl                     wb_msr,

    Delayed_wb_if.frontend                 dwb_ls,
    Delayed_wb_if.frontend                 dwb_io,

    input logic                            io_pipe_empty,
    input logic                            ls_pipe_empty,
    input logic                            vector_pipe_empty,
    input logic                            synapse_busy,
    input logic                            synapse_stall,
    input logic                            vector_ready,

    input Frontend::Frontend_control       ctrl,
    input Frontend::Branch_control         bctrl,
    input Frontend::Interrupt_control      ictrl,

    output Frontend::Predecoded            opf_predec,
    output Frontend::Issue_slot            opf_issue,

    output Frontend::Issue_array           issue_slots,
    output logic                           predicted_taken,
    output logic                           sleeping,
    output logic                           disable_wb,
    output Pu_inst::Inst                   mon_inst,
    output Pu_types::Address               mon_pc );

import Frontend::*;

//---------------------------------------------------------------------------
// Local parameters
//---------------------------------------------------------------------------

localparam bit USE_BCACHE = (OPT_BCACHE > 0) ? 1'b1 : 1'b0;
localparam int BCACHE_WIDTH = OPT_BCACHE;

//---------------------------------------------------------------------------
// Local types and signals
//---------------------------------------------------------------------------

Fetch_state    fst_d;
Fetch_state    fst_stream, fst_stream_d;
Seq_ctr        seq_ctr;
logic          hold_stream;
logic          schedule_stall;
Predecoded     predec, predec_d;
logic          inst_ready;
Issue_array    issue_slots_i;
Fub_readies    ready;
logic          issue;
logic          mc_hold;
logic          pipe_empty_track;
logic          pipe_empty;
logic          ignore_inst;
logic          csync;
logic          int_csync;
logic          disable_wb_i;
logic          jumping, jumping_d;
Branch_control eff_bctrl;
logic          div_stall;
logic          ls_stall;
logic          io_stall;
logic          stalled_by_fubs;
logic          about_to_halt;
Iaddr          ext_int_save_pc;
Delayed_commit del_commit;
Delayed_commit del_com_ls;
Delayed_commit del_com_io;


//---------------------------------------------------------------------------
// Local logic
//---------------------------------------------------------------------------

assign disable_wb = disable_wb_i;

always_ff @(posedge clk)
begin
  issue_slots <= issue_slots_i;
  predicted_taken <= fst_d.predicted_taken;
end

/** Select the instruction for which to fetch operands. */
//always_ff @(posedge clk)
always_comb
begin
  // default assignment
  opf_issue.valid = 1'b0;
  opf_issue.ir = 'x;
  opf_issue.thread = 'x;
  opf_issue.pc = 'x;
  opf_issue.npc = 'x;
  opf_predec = predec_d;

  for(int i=0; i<FUB_ID_END; i++) begin
    if( issue_slots_i[i].valid )
      opf_issue = issue_slots_i[i];
  end
end

always_ff @(posedge clk)
  jumping_d <= jumping & ~fst_d.trans_cmplt;

always_ff @(posedge clk)
  // store the resume address for asynchronous interrupts
  // as a special rule: when sleeping the resume PC is the wait instruction 
  if( issue && !predec_d.is_branch )
    ext_int_save_pc <= fst_d.npc;
  else if( (issue && predec_d.is_branch) || predec_d.halt )
    ext_int_save_pc <= fst_d.pc;

assign int_sched.block_external = csync | jumping_d | (sleeping & ~ctrl.wakeup);
assign int_sched.block = jumping_d;
assign int_sched.pc = issue ? fst_d.pc : ext_int_save_pc;

always_comb begin
  if( ictrl.jump ) begin
    eff_bctrl.jump = 1'b1;
    eff_bctrl.jump_vec = ictrl.jump_vec;
    eff_bctrl.fb_taken = 1'b0;
    eff_bctrl.fb_not_taken = 1'b0;
    eff_bctrl.fb_pc = '0;
  end else begin
    eff_bctrl = bctrl;
  end
end

generate
  if( OPT_DMEM == Pu_types::MEM_BUS ) begin : gen_dmem_bus
    assign
      del_commit.valid = del_com_ls.valid | del_com_io.valid,
      del_commit.gpr = del_com_ls.gpr | del_com_io.gpr;
  end else if( OPT_DMEM == Pu_types::MEM_TIGHT ) begin : gen_dmem_tight
    assign
      del_commit.valid = del_com_io.valid,
      del_commit.gpr = del_com_io.gpr;
  end
endgenerate


//---------------------------------------------------------------------------
// Submodules
//---------------------------------------------------------------------------

// these write-back channels are gated by FUBMs
Wb_channel_if #(.DEST_SIZE(5)) wbc_gpr_p0();
Wb_channel_if #(.DEST_SIZE(5)) wbc_gpr_p1();
Wb_channel_if #(.DEST_SIZE(5)) wbc_gpr_p2();
Wb_channel_if #(.DEST_SIZE(8)) wbc_cr_i();
Wb_channel_if #(.DEST_SIZE($bits(Xer_dest))) wbc_xer_i();

Inst_stream #(
  .addr_width(iaddr_width),
  .use_bcache(USE_BCACHE),
  .bcache_width(BCACHE_WIDTH),
  .output_delay(OPT_IF_LATENCY),
  .bcache_ignores_jumps(OPT_BCACHE_IGNORES_JUMPS),
  .buffer_bctrl(OPT_BUFFER_BCTRL)
) inst_stream (
  .clk,
  .reset,
  .imem,
  .hold(hold_stream | mc_hold),
  .bctrl(eff_bctrl),
  .fst(fst_stream)
);

assign mon_inst = fst_stream.inst;
assign mon_pc = fst_stream.pc;

Predecode #(
  .OPT_DMEM(OPT_DMEM)
) predecode (
  .clk, .reset,
  .fst(fst_stream),
  .seq_ctr,
  .predec
);

Cycle_counter cyc_ctr (
  .clk, .reset,
  .stop_val(predec.multicycles),
  .jump_ignore(jumping & ~fst_stream.trans_cmplt & ~fst_stream_d.trans_cmplt),
  .is_multicycle(predec.is_multicycle),
  //.issue(issue),
  .hold_stream,
  .cur_val(seq_ctr),
  .hold(mc_hold)
);

always_ff @(posedge clk or posedge reset)
  if( reset ) begin
    predec_d <= predecoded_zeros();
    fst_stream_d.valid <= 1'b0;
  end else begin
    if( !hold_stream ) begin
      predec_d <= predec;
      fst_stream_d <= fst_stream;
    end
  end

always_comb begin
  fst_d = fst_stream_d;

  if( ignore_inst )
    fst_d.inst = Pu_inst::INST_NOP;
end


Inst_track #(
  .WRITE_THROUGH(OPT_WRITE_THROUGH),
  .LOOKUP_CACHE(OPT_LOOKUP_CACHE)
) inst_track (
  .clk, .reset,
  .fst(fst_d),
  .predec(predec_d),
  .disable_wb(disable_wb_i),  // disable all wb during contex sync caused by interrupt
  .ready(inst_ready),
  .issue(issue),
  .pipe_empty(pipe_empty_track),
  .wb_gpr(wbc_gpr_p0.ctrl),
  .wb_cr(wbc_cr_i.ctrl),
  .wb_ctr(wb_ctr),
  .wb_lnk(wb_lnk),
  .wb_xer(wbc_xer_i.ctrl),
  .wb_spr(wb_spr),
  .wb_msr(wb_msr),
  .del_commit
);

assign stalled_by_fubs = div_stall | io_stall | ls_stall;
assign hold_stream = (~inst_ready & ~ignore_inst) | schedule_stall | stalled_by_fubs | ext_hold;
assign pipe_empty = pipe_empty_track
    & ~stalled_by_fubs
    & io_pipe_empty
    & ls_pipe_empty
    & vector_pipe_empty
    & ~synapse_busy;
//assign issue = issue_fxdpt_i.valid | issue_branch_i.valid | issue_ls_i.valid | issue_mul_div_i.valid;

always_comb begin
  issue = 1'b0;
  for(int i=0; i<FUB_ID_END; i++) begin
    if( issue_slots_i[i].valid )
      issue = 1'b1;
  end
end


Schedule_single schedule (
  .clk, .reset,
  .ctrl,
  .fst(fst_d),
  //.bctrl(eff_bctrl),
  .bctrl(bctrl),
  .ictrl,
  .inst_ready(inst_ready & ~stalled_by_fubs),
  .predec(predec_d),
  .pipe_empty,
  .ready(ready),
  .issue_slots(issue_slots_i),
  .stall(schedule_stall),
  .about_to_halt,
  .halted(sleeping),
  .ignore_inst,
  .csync,
  .jumping,
  .disable_wb(disable_wb_i)
);


//assign
  //fub_fxdpt_ready = 1'b1,
  //fub_branch_ready = 1'b1,
  //fub_ls_ready = 1'b1;
assign
  ready[FUB_ID_FIXEDPOINT] = 1'b1,
  ready[FUB_ID_BRANCH] = 1'b1,
  ready[FUB_ID_NEVER] = 1'b1,
  ready[FUB_ID_VECTOR] = vector_ready;
  //ready[FUB_ID_LOAD_STORE] = 1'b1;


/*Fub_manager fubm_fxdpt (
  .clk, .reset,
  .ready(fub_fxdpt_ready),
  .issue(issue_fxdpt_i)
);

Fub_manager fubm_branch (
  .clk, .reset,
  .ready(fub_branch_ready),
  .issue(issue_branch_i)
);

Fub_manager fubm_ls (
  .clk, .reset,
  .ready(fub_ls_ready),
  .issue(issue_ls_i)
);*/

//Fubm_load_store fubm_ls(
  //.clk, .reset,
  //.ready(ready[FUB_ID_LOAD_STORE]),
  //.stall(ls_stall),
  //.issue(issue_slots_i[FUB_ID_LOAD_STORE]),
  //.delayed_wb(dwb_ls),

  //.gpr_in(wbc_gpr_p0),
  //.gpr_out(wbc_gpr_p1)
//);

generate
  if( OPT_DMEM == Pu_types::MEM_TIGHT ) begin : gen_fubm_tight
    
    assign ready[FUB_ID_LOAD_STORE] = 1'b1;
    assign ls_stall = 1'b0;
    assign del_com_ls.valid = 1'b0;

    assign
      wbc_gpr_p1.we = wbc_gpr_p0.we,
      wbc_gpr_p1.dest = wbc_gpr_p0.dest,
      wbc_gpr_p1.src = wbc_gpr_p0.src;

  end : gen_fubm_tight
  else
  begin : gen_fubm_bus

    `ARRAY_EXTRACT_IN(Issue_slot, issue_slots_i, FUB_ID_LOAD_STORE)

    Fubm_io #(FUB_LOAD_STORE) fubm_ls (
      .clk, .reset,
      .ready(ready[FUB_ID_LOAD_STORE]),
      .stall(ls_stall),
      //.issue(issue_slots_i[FUB_ID_LOAD_STORE]),
      .issue(`FROM_ARRAY(issue_slots_i, FUB_ID_LOAD_STORE)),
      .predec(predec_d),

      .dwb(dwb_ls),
      .del_commit(del_com_ls),

      .gpr_in(wbc_gpr_p0.wb_channel),
      .gpr_out(wbc_gpr_p1.ctrl)
    );

  end : gen_fubm_bus
endgenerate

assign ready[FUB_ID_MUL_DIV] = 1'b1;
/*Fub_counter #(
  .WAIT_CYCLES(mul_latency),
  .INITIAL_WAIT(1'b1)
) fubm_mul_div (
  .clk, .reset,
  .ready(ready[FUB_ID_MUL_DIV]),
  .issue(issue_slots_i[FUB_ID_MUL_DIV])
);*/

//Fub_counter #(
  //.WAIT_CYCLES(div_latency),
  //.INITIAL_WAIT(1'b1)
//) fubm_div (
  //.clk, .reset,
  //.ready(ready[FUB_ID_DIV]),
  //.issue(issue_slots_i[FUB_ID_DIV])
//);

`ARRAY_EXTRACT_IN(Issue_slot, issue_slots_i, FUB_ID_DIV)

Fubm_div fubm_div (
  .clk, .reset,
  .ready(ready[FUB_ID_DIV]),
  .stall(div_stall),
  //.issue(issue_slots_i[FUB_ID_DIV]),
  .issue(`FROM_ARRAY(issue_slots_i, FUB_ID_DIV)),
  .predec(predec_d),

  .wb_gpr_in(wbc_gpr_p2.wb_channel),
  .wb_gpr_out(wb_gpr),
  .wb_cr_in(wbc_cr_i.wb_channel),
  .wb_cr_out(wb_cr),
  .wb_xer_in(wbc_xer_i.wb_channel),
  .wb_xer_out(wb_xer)
);

`ARRAY_EXTRACT_IN(Issue_slot, issue_slots_i, FUB_ID_IO)

Fubm_io #(FUB_IO) fubm_io (
  .clk, .reset,
  .ready(ready[FUB_ID_IO]),
  .stall(io_stall),
  //.issue(issue_slots_i[FUB_ID_IO]),
  .issue(`FROM_ARRAY(issue_slots_i, FUB_ID_IO)),
  .predec(predec_d),

  .dwb(dwb_io),
  .del_commit(del_com_io),

  .gpr_in(wbc_gpr_p1.wb_channel),
  .gpr_out(wbc_gpr_p2.ctrl)
);


`ARRAY_EXTRACT_IN(Issue_slot, issue_slots_i, FUB_ID_SYNAPSE)

Fubm_synapse fubm_synapse (
  .clk, .reset,
  .ready(ready[FUB_ID_SYNAPSE]),
  .issue(`FROM_ARRAY(issue_slots_i, FUB_ID_SYNAPSE)),
  .predec(predec_d),
  .synapse_busy(synapse_busy),
  .synapse_stall(synapse_stall)
);

  //---------------------------------------------------------------------------
  // Assertions
  //---------------------------------------------------------------------------

  // synopsys translate_off

  //---------------------------------------------------------------------------
  /** Instructions should only be scheduled to one issue slot. */
  property schedule_to_one_slot;
    @(posedge clk) disable iff (reset)
    ( $onehot0({issue_slots_i[0].valid, 
        issue_slots_i[1].valid, 
        issue_slots_i[2].valid, 
        issue_slots_i[3].valid}) );
  endproperty

  check_schedule_to_one_slot: assert property(schedule_to_one_slot);
  //---------------------------------------------------------------------------
  /** Instructions should not be issued to a slot that is not ready. */
  property issued_slot_is_ready;
    @(posedge clk) disable iff(reset)
    (( issue_slots_i[0].valid |-> ready[0] )
     and ( issue_slots_i[1].valid |-> ready[1] )
     and ( issue_slots_i[2].valid |-> ready[2])
     and ( issue_slots_i[3].valid |-> ready[3]) );
  endproperty

  check_issued_slot_is_ready: assert property(issued_slot_is_ready);
  //---------------------------------------------------------------------------
  /** All instructions should be issued at some point (except wait) */
  /*property issue_all;
    Pu_inst::Inst i;
    Iaddr a;

    @(posedge clk) disable iff(reset)
    ( (fst.valid, i = fst.inst, a = fst.pc)
      ##[0:$] issue
      |-> ( (issue_fxdpt_i.valid && (issue_fxdpt_i.ir == i) && (issue_fxdpt_i.pc == a))
        || (issue_branch_i.valid && (issue_branch_i.ir == i) && (issue_branch_i.pc == a))
        || (issue_ls_i.valid && (issue_ls_i.ir == i) && (issue_ls_i.pc == a)) )
    );
  endproperty

  check_issue_all: assert property(issue_all);*/
  //---------------------------------------------------------------------------
  /** Multi-cycle instructions should be issued once for every cycle. */
  //property multi_cycle_issue;
    //int n;
    //int c;

    //@(posedge clk) disable iff(reset)
    //( (predec.is_multicycle, n=predec.multicycles, c=0) 
      //|-> (((issue, c=c+1) ##1 (!issue [* 0:$])) [* 0:31]) 
        //##1 (c == n) );
  //endproperty

  //check_multi_cycle_issue: assert property(multi_cycle_issue) 
    //else $error("Multi-cycle instruction not issued correctly");
  //---------------------------------------------------------------------------

  // synopsys translate_on

  endmodule


  //---------------------------------------------------------------------------
  //module Cycle_counter
    //( input logic clk, reset,
      //input Seq_ctr stop_val,
      //input logic start,
      //input logic count,
      //output Seq_ctr cur_val,
      //output logic done );

    //Seq_ctr ctr, next_ctr;
    //logic done_i;


    //always_comb begin
      //if( done_i ) begin
        //next_ctr = 0;
      //end else  begin
        //if( count )
          //next_ctr = ctr + 1;
        //else
          //next_ctr = ctr;
      //end
    //end

    //always_ff @(posedge clk or posedge reset)
      //if( reset ) begin
        //ctr <= '0;
        //done_i <= 1'b0;
      //end else begin
        //ctr <= next_ctr;

        //if( next_ctr == stop_val )
          //done_i <= start;//1'b1;
        //else //if( start )
          //done_i <= 1'b0;
      //end

    //assign cur_val = ctr;
    //assign done = done_i & count;

  //endmodule
  //---------------------------------------------------------------------------


  //---------------------------------------------------------------------------
  module Fub_counter
  #(parameter int unsigned WAIT_CYCLES = 4,
    parameter bit INITIAL_WAIT = 1'b1 )
  ( input logic clk, reset,
    output logic ready,
    input Frontend::Issue_slot issue );

  import Frontend::*;

  typedef logic[Pu_types::clog2(WAIT_CYCLES)-1:0] Counter;


  Counter ctr, next_ctr;


  always_comb begin
    // default assignment
    next_ctr = 0;

    if( issue.valid )
      next_ctr = WAIT_CYCLES-1;
    else if( ctr != 0 )
      next_ctr = ctr - 1;
  end

  always_ff @(posedge clk or posedge reset)
    if( reset ) begin
      if( INITIAL_WAIT ) begin
        ctr <= WAIT_CYCLES-1;
        ready <= 1'b0;
      end else begin
        ctr <= '0;
        ready <= 1'b1;
      end
    end else begin
      ctr <= next_ctr;

      if( ctr == 0 )
        ready <= (issue.valid) ? 1'b0 : 1'b1;
      else
        ready <= 1'b0;
    end

endmodule
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
module Fubm_div
  ( input logic clk, reset,
    output logic ready,
    output logic stall,
    input Frontend::Issue_slot issue,
    input Frontend::Predecoded predec,
    Wb_channel_if.wb_channel wb_gpr_in,
    Wb_channel_if.ctrl wb_gpr_out,
    Wb_channel_if.wb_channel wb_cr_in,
    Wb_channel_if.ctrl wb_cr_out,
    Wb_channel_if.wb_channel wb_xer_in,
    Wb_channel_if.ctrl wb_xer_out );

  import Frontend::*;

  logic on_state;
  logic ctr_ready;
  logic wb_ready;

  Pu_types::Reg_index gpr_dest;
  logic[7:0] cr_dest;
  Xer_dest xer_dest;
  logic oe;
  

  Fub_counter #(
    .WAIT_CYCLES(div_latency),
    .INITIAL_WAIT(1'b1)
  ) ctr (
    .clk, .reset,
    .ready(ctr_ready),
    .issue(issue)
  );

  assign ready = ctr_ready & wb_ready;

  always_ff @(posedge clk or posedge reset)
    if( reset ) begin
      on_state <= 1'b0;
      gpr_dest <= '0;
      cr_dest <= '0;
      oe <= 1'b0;
    end else
      if( issue.valid ) begin
        on_state <= 1'b1;
        gpr_dest <= predec.rt;
        cr_dest <= predec.write_cr;
        oe <= predec.write_xer;
      end else if( on_state && ctr_ready && wb_ready )
        on_state <= 1'b0;

  always_comb begin
    // default assignment
    wb_gpr_out.we = wb_gpr_in.we;
    wb_gpr_out.dest = wb_gpr_in.dest;
    wb_gpr_out.src = wb_gpr_in.src;
    wb_cr_out.we = wb_cr_in.we;
    wb_cr_out.dest = wb_cr_in.dest;
    wb_cr_out.src = wb_cr_in.src;
    wb_xer_out.we = wb_xer_in.we;
    wb_xer_out.dest = wb_xer_in.dest;
    wb_xer_out.src = wb_xer_in.src;

    wb_ready = ~on_state;
    stall = on_state;

    if( on_state && ctr_ready && !wb_gpr_in.we && (!wb_cr_in.we || ~(| cr_dest)) && (!wb_xer_in.we || !oe) ) begin
      wb_gpr_out.we = 1'b1;
      wb_gpr_out.dest = gpr_dest;
      wb_gpr_out.src = FUB_DIV;
      wb_cr_out.we = (| cr_dest);
      wb_cr_out.dest = cr_dest;
      wb_cr_out.src = FUB_DIV;
      wb_xer_out.we = oe;
      wb_xer_out.dest = XER_DEST_OV;
      wb_xer_out.src = FUB_DIV;

      wb_ready = 1'b1;
      stall = 1'b0;
    end
  end
endmodule
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
module Fubm_load_store
  ( input logic clk, reset,
    output logic ready,
    output logic stall,
    input Frontend::Issue_slot issue,
    Delayed_wb_if.frontend delayed_wb,
    output Frontend::Delayed_commit del_commit,

    Wb_channel_if.wb_channel gpr_in,
    Wb_channel_if.ctrl gpr_out);

  import Frontend::*;

  logic ack;
  logic next_ack;
  logic next_ignore, ignore;

  always_comb begin
    // default assignments
    gpr_out.we = gpr_in.we;
    gpr_out.dest = gpr_in.dest;
    gpr_out.src = gpr_in.src;
    ready = 1'b1;
    stall = 1'b0;
    next_ack = 1'b0;
    next_ignore = 1'b0;
    del_commit.valid = 1'b0;
    del_commit.gpr = '0;

    if( delayed_wb.delayed ) begin
      stall = 1'b1;
      ready = 1'b0;

      if( delayed_wb.wb_req & ack & ignore )
        next_ignore = 1'b0;
      else
        next_ignore = ignore;

      if( (delayed_wb.wb_dest == gpr_in.dest) 
          && delayed_wb.wb_dest_valid
          && gpr_in.we 
          && !delayed_wb.scheduled_wb ) 
      begin
        next_ack = 1'b1;
        next_ignore = 1'b1;
      end

      if( !ignore && delayed_wb.wb_req && !gpr_in.we ) begin
        gpr_out.we = 1'b1;
        gpr_out.src = FUB_LOAD_STORE;
        gpr_out.dest = delayed_wb.wb_dest;
        next_ack = 1'b1;
      end
      
      if( next_ack ) begin
        del_commit.valid = 1'b1;
        del_commit.gpr = delayed_wb.wb_dest;
      end
    end
  end

  always_ff @(posedge clk or posedge reset)
    if( reset ) begin
      ack <= 1'b0;
      ignore <= 1'b0;
    end else begin
      ack <= next_ack;
      ignore <= next_ignore;
    end


  assign delayed_wb.wb_ack = ack;

endmodule
//---------------------------------------------------------------------------
module Fubm_io
  #(parameter Frontend::Fu_set src_fub = Frontend::FUB_IO )
  ( input logic clk, reset,
    output logic ready,
    output logic stall,
    input Frontend::Issue_slot issue,
    input Frontend::Predecoded predec,
    Delayed_wb_if.frontend dwb,
    output Frontend::Delayed_commit del_commit,
  
    Wb_channel_if.wb_channel gpr_in,
    Wb_channel_if.ctrl gpr_out);

  import Frontend::*;

/* Stall immediately and wait for delayed wb request from FUB. */
  logic ack, next_ack;
  Frontend::Delayed_commit next_del_commit;

  assign ready = ~dwb.delayed;
  assign stall = 1'b0;

  always_comb begin
    // default assignments
    //next_ack = 1'b0;
    next_ack = !gpr_in.we;
    gpr_out.we = gpr_in.we;
    gpr_out.src = gpr_in.src;
    gpr_out.dest = gpr_in.dest;
    next_del_commit.valid = 1'b0;
    next_del_commit.gpr = '0;

    if( dwb.wb_req && !dwb.wb_cancel && !gpr_in.we ) begin
      gpr_out.we = 1'b1;
      gpr_out.src = src_fub;
      gpr_out.dest = dwb.wb_dest;
      next_ack = 1'b1;

      next_del_commit.valid = 1'b1;
      next_del_commit.gpr = dwb.wb_dest;
    end else if( dwb.wb_req && dwb.wb_cancel ) begin
      next_ack = 1'b1;
      next_del_commit.valid = 1'b1;
      next_del_commit.gpr = dwb.wb_dest;
    end
  end


  always_ff @(posedge clk or posedge reset)
    if( reset ) begin
      ack <= 1'b0;
      //del_commit.valid <= 1'b0;
      //del_commit.gpr <= '0;
    end else begin
      ack <= next_ack;
      //del_commit <= next_del_commit;
    end

  assign del_commit = next_del_commit;

  //assign dwb.wb_ack = ack;
  assign dwb.wb_ack = next_ack;

endmodule
//---------------------------------------------------------------------------
module Fubm_synapse
  ( input logic clk, reset,
    output logic ready,
    input logic synapse_busy,
    input logic synapse_stall,
    input Frontend::Issue_slot issue,
    input Frontend::Predecoded predec );

  import Pu_inst::*;

  Inst ir;

  assign ir = issue.ir;

  always_comb begin
    //ready = 1'b1;
    ready = ~(synapse_busy & predec.mem_bar) & ~(synapse_stall & predec.synops);

    //if( (ir.x.opcd == Op_nve_xo) 
      //&& ((ir.x.xo == Xop_synops) || (ir.x.xo == Xop_synswp)) )
    //begin
      //ready = ~synapse_busy;
    //end
  end

endmodule
//---------------------------------------------------------------------------

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
