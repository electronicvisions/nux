// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


module Fub_fixedpoint #(parameter bit WITH_MULTIPLIER = 1'b1,
			parameter bit WITH_DIVIDER = 1'b1)
  ( input logic clk, reset,

    input Frontend::Issue_slot inst,
    Operand_if.read opbus,

    output Backend::Result_bus resbus );

import Backend::*;
import Pu_inst::*;
import Pu_types::*;

Inst ir, ir_d;
Word bb;
Frontend::Thread_id thread_d;
logic[4:0] rot_dist, next_rot_dist;
logic[4:0] rot_start, next_rot_start;
logic[4:0] rot_stop, next_rot_stop;


Fixedpoint_ctrl_if ctrl(.clk, .reset);
Fixedpoint_data_if data();

Dec_fixedpoint decode(
  .clk,
  .reset,
  .inst,
  .ctrl(ctrl.decode)
);


assign
  data.alu_a_in = opbus.opbus_0.a,
  data.alu_b_in = opbus.opbus_0.b,
  data.alu_cin = opbus.opbus_0.cin,
  data.alu_cr_in = opbus.opbus_0.cr,
  data.rotm_x_in = opbus.opbus_0.a,
  data.rotm_q_in = opbus.opbus_0.c,
  data.rotm_sh = next_rot_dist,
  data.rotm_ma = next_rot_start,
  data.rotm_mb = next_rot_stop,
  data.spreu_a_in = opbus.opbus_0.a,
  data.spreu_cr_in = opbus.opbus_0.cr,
  data.spreu_sprin = opbus.opbus_0.b,   // XXX
  data.spreu_msrin = opbus.opbus_0.c,   // XXX
  data.mul_a_in = opbus.opbus_0.a,
  data.mul_b_in = opbus.opbus_0.b,
  data.div_a_in = opbus.opbus_0.a,
  data.div_b_in = opbus.opbus_0.b;
//assign
  //data.alu_a_in = opbus.opbus[thread_d].a,
  //data.alu_b_in = opbus.opbus[thread_d].b,
  //data.alu_cin = opbus.opbus[thread_d].cin,
  //data.alu_cr_in = opbus.opbus[thread_d].cr,
  //data.rotm_x_in = opbus.opbus[thread_d].a,
  //data.rotm_q_in = opbus.opbus[thread_d].c,
  //data.rotm_sh = next_rot_dist,
  //data.rotm_ma = next_rot_start,
  //data.rotm_mb = next_rot_stop,
  //data.spreu_a_in = opbus.opbus[thread_d].a,
  //data.spreu_cr_in = opbus.opbus[thread_d].cr,
  //data.spreu_sprin = opbus.opbus[thread_d].b,   // XXX
  //data.spreu_msrin = opbus.opbus[thread_d].c,   // XXX
  //data.mul_a_in = opbus.opbus[thread_d].a,
  //data.mul_b_in = opbus.opbus[thread_d].b,
  //data.div_a_in = opbus.opbus[thread_d].a,
  //data.div_b_in = opbus.opbus[thread_d].b;

//always_comb bb = opbus.get_opbus_b(thread_d);
assign bb = opbus.opbus_0.b;
assign ir = inst.ir;

//---------------------------------------------------------------------------
// Generate shift/rotate signals to Rotm 
//---------------------------------------------------------------------------
always_comb
begin : ctrl_rotl
  logic[15:0] cop;

  next_rot_dist  = 5'b00000;
  next_rot_start = 5'b00000;
  next_rot_stop  = 5'b00000;

  cop = {ir_d.x.opcd, ir_d.x.xo};
  unique casez(cop)
    {Op_rlwimi, 10'bzzzzzzzzzz},
    {Op_rlwinm, 10'bzzzzzzzzzz}: begin
      next_rot_dist  = ir_d.m.rb;
      next_rot_start = ir_d.m.mb;
      next_rot_stop  = ir_d.m.me;
    end

    {Op_rlwnm, 10'bzzzzzzzzzz}: begin
      next_rot_dist  = bb[4:0];
      next_rot_start = ir_d.m.mb;
      next_rot_stop  = ir_d.m.me;
    end

    {Op_alu_xo, Xop_slw}: begin
      next_rot_dist  = bb[4:0];
      next_rot_start = 5'b00000;
      next_rot_stop  = 31 - bb[4:0];
    end

    {Op_alu_xo, Xop_srw}: begin
      next_rot_dist  = 32 - bb[4:0];
      next_rot_start = bb[4:0];
      next_rot_stop  = 5'b11111;
    end

    {Op_alu_xo, Xop_srawi}: begin
      next_rot_dist  = 32 - ir_d.x.rb;
      next_rot_start = ir_d.x.rb;
      next_rot_stop  = 5'b11111;
    end

    {Op_alu_xo, Xop_sraw}: begin
      next_rot_dist  = 32 - bb[4:0];
      next_rot_start = bb[4:0];
      next_rot_stop  = 5'b11111;
    end

    default: begin
    end
  endcase
end : ctrl_rotl

always_ff @(posedge clk)
begin
  //rot_dist <= next_rot_dist;
  //rot_start <= next_rot_start;
  //rot_stop <= next_rot_stop;
  thread_d = inst.thread;
  ir_d = ir;
end

// TODO: Christian
// Why is the multiplier and divider disabled?
Fixedpoint #(
  .WITH_MULTIPLIER(WITH_MULTIPLIER),
  .WITH_DIVIDER(WITH_DIVIDER)
) fixedpoint(
  .clk,
  .reset,
  .ctrl(ctrl.internal),
  .data(data.execute),
  .so(opbus.opbus_0.so),
  .result(resbus)
);

endmodule

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
