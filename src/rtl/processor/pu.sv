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

module Pu_v2
	#(
		/** Configure the branch predictor:
		* 0  : Disable branch prediction
		* >0 : Use branch prediction. The parameter then specifies how many
		* instruction address bits are used for the prediction table. */
		parameter int OPT_BCACHE = 0,

		/** Set this option to integrate a multiply functional unit. */
		parameter bit OPT_MULTIPLIER = 1'b1,

		/** Set this option to integrate a divide functional unit. */
		parameter bit OPT_DIVIDER = 1'b1,

		/** Set this option to use the iobus module. */
		parameter bit OPT_IOBUS = 1'b0,

		/** Set this option to include the fixed-point vector SIMD unit */
		parameter bit OPT_VECTOR = 1'b0,

		/** The vector functional unit uses multiple datapath slices in
		* parallel. Since it is an SIMD unit, all slices execute the same
		* instruction, but on different data using local registers. */
		parameter int OPT_VECTOR_SLICES = 8,

		/** One vector consists of multiple 16 bit wide half-word elements. This
		* option configures how many of them are implemented. */
		parameter int OPT_VECTOR_NUM_HALFWORDS = 8,

		/** Configure the delay of the vector multiplier. */
		parameter int OPT_VECTOR_MULT_DELAY = 4,

		/** Configure the delay of the vector adder after the multiplier. */
		parameter int OPT_VECTOR_ADD_DELAY = 1,

		/** Number of entries in the instruction queue from
		* general-purpose processor to vector unit. */
		parameter int OPT_VECTOR_INST_QUEUE_DEPTH = 4,

		/** Set this option to use the NibblE VEctoR Extension (NEVER) */
		parameter bit OPT_NEVER = 1'b0,

		/** Set this option to use the SYNapse ProceSsing Extension (SYNAPSE) */
		parameter bit OPT_SYNAPSE = 1'b0,

		/** Select the data memory interface:
		* MEM_TIGHT  -  Using the Ram_if port dmem for memories with
		*               a guaranteed fixed latency.
		* MEM_BUS    -  Using the OCP Bus_if port dmem_bus for ports with
		*               arbitrary latency. */
		parameter Pu_types::Opt_mem OPT_DMEM = Pu_types::MEM_BUS,

		/** Set the number of pipeline registers between the instruction
		* memory and the predecode stage. */
		parameter int OPT_IF_LATENCY = 1,

		/** Removes a long timing path: bcache does not predict for
		* instruction locations that are targets of branches. */
		parameter bit OPT_BCACHE_IGNORES_JUMPS = 1'b1,

		/** Increase branch latency by one cycle. Possibly removes a
		* long timing arc from the branch functional unit to the
		* inst_stream module. */
		parameter bit OPT_BUFFER_BCTRL = 1'b0,

		/** A write to the GPR file is passed to the reader in the same cycle
		* */
		parameter bit OPT_WRITE_THROUGH = 1'b1,

		/** Instruction tracking for GPRs uses the lookup-cache method.
		* Required if delayed write-back to GPRs is used (e.g. OPT_DMEM
		* = MEM_BUS). */
		parameter bit OPT_LOOKUP_CACHE = 1'b1
	)
	(	input logic             clk,
		input logic             reset,

		input logic             hold,  // actually: hold instruction fetch

		//Gpr_file.processor  gpr_file,
		Ram_if.client           imem,
		Ram_if.client           dmem,
		Bus_if.master           dmem_bus,
		Bus_if.master           iobus,
		Bus_if.master           vector_bus,
		Bus_if.master           vector_pbus,

		output Pu_types::Word   gout,
		input  Pu_types::Word   gin,
		output Pu_types::Word   goe,

		Pu_ctrl_if.pu           ctrl,
		Timer_if.pu             timer,

		Syn_io_if.client        syn_io_a,
		Syn_io_if.client        syn_io_b
	);

import Pu_types::*;
import Pu_inst::*;
import Pu_interrupt::*;
import Frontend::*;
import Backend::*;

//---------------------------------------------------------------------------
// Local types and signals
//---------------------------------------------------------------------------

Frontend_control frontend_control;
Branch_control branch_control;
Interrupt_control interrupt_control;
Predecoded opf_predec;
Predecoded issue_predec;
Issue_slot opf_issue;
Issue_array issue;
//Issue_slot issue_fxdpt;
//Issue_slot issue_branch;
//Issue_slot issue_ls;
//Issue_slot issue_mul_div;
Result_bus_array res;
//Result_bus res_fxdpt;
//Result_bus res_branch;
//Result_bus res_ls;
//Result_bus res_mul_div;
Operands opbus_i;
logic predicted_taken;
logic io_pipe_empty;
logic ls_pipe_empty;
logic vector_pipe_empty;
logic synapse_busy;
logic synapse_stall;
logic disable_wb;
logic vector_ready;

////---------------------------------------------------------------------------
//// Interfaces
////---------------------------------------------------------------------------

Operand_if             opbus();
Result_if              resbus();
Gpr_file_if            gpr_file_if();
Register_file_if       register_file_if();
//Bypass_if              bypass_if(.clk(clk));
Int_sched_if           int_sched_if(.clk(clk), .reset(reset));
Timer_if               timer_i();


Wb_channel_if #(.DEST_SIZE(5)) wbc_gpr();
Wb_channel_if #(.DEST_SIZE(8)) wbc_cr();
Wb_channel_if #(.DEST_SIZE(1)) wbc_lnk();
Wb_channel_if #(.DEST_SIZE(1)) wbc_ctr();
Wb_channel_if #(.DEST_SIZE($bits(Xer_dest))) wbc_xer();
Wb_channel_if #(.DEST_SIZE(10)) wbc_spr();
Wb_channel_if #(.DEST_SIZE(1)) wbc_msr();

Delayed_wb_if #(.DEST_SIZE(5)) dwb_ls();
Delayed_wb_if #(.DEST_SIZE(5)) dwb_io();



always_comb begin
	timer_i.tbu = timer.tbu;
	timer_i.tbl = timer.tbl;
	timer_i.dec = timer.dec;
	timer_i.decar = timer.decar;
	timer_i.tcr = timer.tcr;
	timer_i.tsr = timer.tsr;

	timer.tbu_in = timer_i.tbu_in;
	timer.tbl_in = timer_i.tbl_in;
	timer.dec_in = timer_i.dec_in;
	timer.decar_in = timer_i.decar_in;
	timer.tcr_in = timer_i.tcr_in;
	timer.tsr_in = timer_i.tsr_in;
	timer.tbu_we = timer_i.tbu_we;
	timer.tbl_we = timer_i.tbl_we;
	timer.dec_we = timer_i.dec_we;
	timer.decar_we = timer_i.decar_we;
	timer.tcr_we = timer_i.tcr_we;
	timer.tsr_we = timer_i.tsr_we;
end


// Pipeline stages & submodules
Frontend_single #(
	.OPT_BCACHE(OPT_BCACHE),
	.OPT_IF_LATENCY(OPT_IF_LATENCY),
	.OPT_DMEM(OPT_DMEM),
	.OPT_BCACHE_IGNORES_JUMPS(OPT_BCACHE_IGNORES_JUMPS),
	.OPT_BUFFER_BCTRL(OPT_BUFFER_BCTRL),
	.OPT_WRITE_THROUGH(OPT_WRITE_THROUGH),
	.OPT_LOOKUP_CACHE(OPT_LOOKUP_CACHE)
) frontend (
	.clk,
	.reset,
	.ext_hold(hold),

	.int_sched(int_sched_if.frontend),

	.imem,
	//.reg_file(register_file_if),
	.wb_gpr(wbc_gpr.ctrl),
	.wb_cr(wbc_cr.ctrl),
	.wb_ctr(wbc_ctr.ctrl),
	.wb_lnk(wbc_lnk.ctrl),
	.wb_xer(wbc_xer.ctrl),
	.wb_spr(wbc_spr.ctrl),
	.wb_msr(wbc_msr.ctrl),

	.dwb_ls(dwb_ls.frontend),
	.dwb_io(dwb_io.frontend),

	.io_pipe_empty,
	.ls_pipe_empty,
	.vector_pipe_empty,
	.synapse_busy,
	.synapse_stall,
	.vector_ready,

	.ctrl(frontend_control),
	.bctrl(branch_control),
	.ictrl(interrupt_control),

	.opf_predec(opf_predec),
	.opf_issue(opf_issue),

	.issue_slots(issue),
	.predicted_taken,
	.disable_wb,
	//.issue_fxdpt(issue_fxdpt),
	//.issue_branch(issue_branch),
	//.issue_ls(issue_ls),
	//.issue_mul_div(issue_mul_div),

	.sleeping(ctrl.sleep),
	.mon_inst(ctrl.mon_inst),
	.mon_pc(ctrl.mon_pc)
);

Operand_fetch op_fetch (
	.clk, .reset,
	.register_file(register_file_if.read),
	.timer(timer_i.op_fetch),
	.inst(opf_issue),
	.predec(opf_predec),
	//.ops(opbus_i)
	.opbus(opbus.write)
);

always_ff @(posedge clk)
begin
	issue_predec <= opf_predec;
end

//always_comb opbus.set_opbus(0, opbus_i);

`ARRAY_EXTRACT_IN(Issue_slot, issue, FUB_ID_FIXEDPOINT)
`ARRAY_EXTRACT_OUT(Result_bus, res, FUB_ID_FIXEDPOINT)
Fub_fixedpoint #(.WITH_MULTIPLIER(1'b0), // we don't use the internal multiplier
		 .WITH_DIVIDER(1'b0))    // and divider any more.
fub_fxdpt (
	.clk, .reset,
	//.inst(issue[FUB_ID_FIXEDPOINT]),
	.inst(`FROM_ARRAY(issue, FUB_ID_FIXEDPOINT)),
	.opbus(opbus.read),
	//.resbus(res[FUB_ID_FIXEDPOINT])
	.resbus(`FROM_ARRAY(res, FUB_ID_FIXEDPOINT))
);

`ARRAY_EXTRACT_IN(Issue_slot, issue, FUB_ID_BRANCH)
`ARRAY_EXTRACT_OUT(Result_bus, res, FUB_ID_BRANCH)
Fub_branch fub_branch (
	.clk, .reset,
	//.inst(issue[FUB_ID_BRANCH]),
	.inst(`FROM_ARRAY(issue, FUB_ID_BRANCH)),
	.predicted_taken,
	.disable_wb,
	.lnk(register_file_if.lnk),
	.ctr(register_file_if.ctr),
	.srr0(register_file_if.srr0),
	.csrr0(register_file_if.csrr0),
	.mcsrr0(register_file_if.mcsrr0),
	.cr(register_file_if.cr),
	.opbus(opbus.read),
	//.resbus(res[FUB_ID_BRANCH]),
	.resbus(`FROM_ARRAY(res, FUB_ID_BRANCH)),
	.bctrl(branch_control),
	.except(int_sched_if.trap)
);

/*Branch branch
	(	.clk(clk),
		.reset(reset),
		.ctrl(branch_ctrl.branch),
		.data(branch_data.branch),
		.inst_fetch(inst_fetch_ctrl.branch),
		.write_back(write_back_data.branch) );

Trap trap (
	.clk(clk),
	.reset(reset),
	.ctrl(trap_ctrl.trap),
	.data(trap_data.trap),
	.except(int_sched_if.trap)
); */


generate if( OPT_DMEM == MEM_TIGHT ) begin : gen_dmem_tight
	`ARRAY_EXTRACT_IN(Issue_slot, issue, FUB_ID_LOAD_STORE)
	`ARRAY_EXTRACT_OUT(Result_bus, res, FUB_ID_LOAD_STORE)
	Fub_load_store fub_ls (
		.clk, .reset,
		//.inst(issue[FUB_ID_LOAD_STORE]),
		.inst(`FROM_ARRAY(issue, FUB_ID_LOAD_STORE)),
		.opbus(opbus.read),
		//.resbus(res[FUB_ID_LOAD_STORE]),
		.resbus(`FROM_ARRAY(res, FUB_ID_LOAD_STORE)),
		.dmem,
		.int_sched_if(int_sched_if.load_store)
	);

	assign ls_pipe_empty = 1'b1;
end : gen_dmem_tight
else if( OPT_DMEM == MEM_BUS ) begin : gen_dmem_bus
	`ARRAY_EXTRACT_IN(Issue_slot, issue, FUB_ID_LOAD_STORE)
	`ARRAY_EXTRACT_OUT(Result_bus, res, FUB_ID_LOAD_STORE)
	Fub_ls_var fub_ls (
		.clk, .reset,
		//.inst(issue[FUB_ID_LOAD_STORE]),
		.inst(`FROM_ARRAY(issue, FUB_ID_LOAD_STORE)),
		.predec(issue_predec),
		.opbus(opbus.read),
		//.resbus(res[FUB_ID_LOAD_STORE]),
		.resbus(`FROM_ARRAY(res, FUB_ID_LOAD_STORE)),
		.int_sched_if(int_sched_if.load_store),
		.iobus(dmem_bus),
		.dwb(dwb_ls.fub),
		.pipe_empty(ls_pipe_empty)
	);
end : gen_dmem_bus
endgenerate


generate if( OPT_MULTIPLIER == 1'b1 ) begin : gen_fub_mul
	`ARRAY_EXTRACT_IN(Issue_slot, issue, FUB_ID_MUL_DIV)
	`ARRAY_EXTRACT_OUT(Result_bus, res, FUB_ID_MUL_DIV)
	Fub_mul fub_mul (
		.clk, .reset,
		//.inst(issue[FUB_ID_MUL_DIV]),
		.inst(`FROM_ARRAY(issue, FUB_ID_MUL_DIV)),
		.opbus(opbus.read),
		//.resbus(res[FUB_ID_MUL_DIV])
		.resbus(`FROM_ARRAY(res, FUB_ID_MUL_DIV))
	);
end : gen_fub_mul
endgenerate

generate if( OPT_DIVIDER == 1'b1 ) begin : gen_fub_div
	`ARRAY_EXTRACT_IN(Issue_slot, issue, FUB_ID_DIV)
	`ARRAY_EXTRACT_OUT(Result_bus, res, FUB_ID_DIV)
	Fub_div fub_div (
		.clk, .reset,
		//.inst(issue[FUB_ID_DIV]),
		.inst(`FROM_ARRAY(issue, FUB_ID_DIV)),
		.opbus(opbus.read),
		//.resbus(res[FUB_ID_DIV])
		.resbus(`FROM_ARRAY(res, FUB_ID_DIV))
	);
end : gen_fub_div
endgenerate


generate if( OPT_IOBUS == 1'b1 ) begin : gen_fub_io
	`ARRAY_EXTRACT_IN(Issue_slot, issue, FUB_ID_IO)
	`ARRAY_EXTRACT_OUT(Result_bus, res, FUB_ID_IO)
	Fub_io fub_io (
		.clk, .reset,
		//.inst(issue[FUB_ID_IO]),
		.inst(`FROM_ARRAY(issue, FUB_ID_IO)),
		.opbus(opbus.read),
		//.resbus(res[FUB_ID_IO]),
		.resbus(`FROM_ARRAY(res, FUB_ID_IO)),
		.pipe_empty(io_pipe_empty),
		.iobus(iobus),
		.dwb(dwb_io.fub)
	);
end : gen_fub_io
else
begin : no_fub_io
	assign io_pipe_empty = 1'b1;
end : no_fub_io
endgenerate


generate if( OPT_VECTOR == 1'b1 ) begin : gen_fub_vector
	`ARRAY_EXTRACT_IN(Issue_slot, issue, FUB_ID_VECTOR)
	`ARRAY_EXTRACT_OUT(Result_bus, res, FUB_ID_VECTOR)
	Fub_vector #(
		.NUM_SLICES(OPT_VECTOR_SLICES),
		.NUM_ELEMS(OPT_VECTOR_NUM_HALFWORDS),
		.ELEM_SIZE(16),
		.VRF_SIZE(32),
		.MULT_STAGES(OPT_VECTOR_MULT_DELAY),
		.ADD_STAGES(OPT_VECTOR_ADD_DELAY),
		.INST_QUEUE_DEPTH(OPT_VECTOR_INST_QUEUE_DEPTH),
		.PLS_WIDTH(OPT_VECTOR_SLICES * OPT_VECTOR_NUM_HALFWORDS * 16)
	) fub_vector (
		.clk,
		.reset,
		.inst(`FROM_ARRAY(issue, FUB_ID_VECTOR)),
		.predec(),
		.opbus(opbus.read),
		.resbus(`FROM_ARRAY(res, FUB_ID_VECTOR)),
		.pipe_empty(vector_pipe_empty),
		.ready(vector_ready),
		.bus(vector_bus),
		.pbus(vector_pbus)
	);
end : gen_fub_vector
else
begin : gen_no_fub_vector

	assign vector_pipe_empty = 1'b1;

	Bus_master_terminator term_vector_bus(vector_bus);
	Bus_master_terminator term_vector_pbus(vector_pbus);

end : gen_no_fub_vector
endgenerate


generate if( OPT_NEVER == 1'b1 ) begin : gen_fub_never

	`ARRAY_EXTRACT_IN(Issue_slot, issue, FUB_ID_NEVER)
	`ARRAY_EXTRACT_OUT(Result_bus, res, FUB_ID_NEVER)
	Fub_never fub_never (
		.clk, .reset,
		.inst(`FROM_ARRAY(issue, FUB_ID_NEVER)),
		.opbus(opbus.read),
		.resbus(`FROM_ARRAY(res, FUB_ID_NEVER))
	);

end : gen_fub_never
endgenerate

generate if( OPT_SYNAPSE == 1'b1 ) begin : gen_fub_synapse

	`ARRAY_EXTRACT_IN(Issue_slot, issue, FUB_ID_SYNAPSE)
	`ARRAY_EXTRACT_OUT(Result_bus, res, FUB_ID_SYNAPSE)

	Fub_synapse fub_synaspe (
		.clk, .reset,
		.inst(`FROM_ARRAY(issue, FUB_ID_SYNAPSE)),
		.opbus(opbus.read),
		.resbus(`FROM_ARRAY(res, FUB_ID_SYNAPSE)),
		.syn_io_a(syn_io_a),
		.syn_io_b(syn_io_b),
		.synapse_busy,
		.synapse_stall
	);

end : gen_fub_synapse
else
begin : gen_no_fub_synapse

	assign
		synapse_busy = 1'b0,
		synapse_stall = 1'b0;

end : gen_no_fub_synapse
endgenerate

//assign res_ar[fu_set_id(FUB_FIXEDPOINT)] = res_fxdpt;
//always_comb begin
	//const int id_fxdpt = fu_set_id(FUB_FIXEDPOINT);
	//const int id_ls = fu_set_id(FUB_LOAD_STORE);
	//const int id_branch = fu_set_id(FUB_BRANCH);
	//const int id_mul_div = fu_set_id(FUB_MUL_DIV);
	//resbus.res[id_fxdpt] = res_fxdpt;
	//resbus.res[id_branch] = res_branch;
	//resbus.res[id_ls] = res_ls;
	//resbus.res[id_mul_div] = res_mul_div;
//end
//assign resbus.res = res;
//always_comb resbus.set_res(res);

always_comb begin
	const int id_fxdpt = fu_set_id(FUB_FIXEDPOINT);
	const int id_ls = fu_set_id(FUB_LOAD_STORE);
	const int id_branch = fu_set_id(FUB_BRANCH);
	const int id_mul_div = fu_set_id(FUB_MUL_DIV);
	const int id_div = fu_set_id(FUB_DIV);
	const int id_io = fu_set_id(FUB_IO);
	const int id_never = fu_set_id(FUB_NEVER);
	const int id_synapse = fu_set_id(FUB_SYNAPSE);
	resbus.set_res(id_fxdpt, res[id_fxdpt]);
	resbus.set_res(id_branch, res[id_branch]);
	resbus.set_res(id_ls, res[id_ls]);
	resbus.set_res(id_mul_div, res[id_mul_div]);
	resbus.set_res(id_div, res[id_div]);
	resbus.set_res(id_io, res[id_io]);
	resbus.set_res(id_never, res[id_never]);
	resbus.set_res(id_synapse, res[id_synapse]);
end

Write_back write_back (
	.clk, .reset,

	.c_gpr(wbc_gpr.wb_channel),
	.c_cr(wbc_cr.wb_channel),
	.c_xer(wbc_xer.wb_channel),
	.c_lnk(wbc_lnk.wb_channel),
	.c_ctr(wbc_ctr.wb_channel),
	.c_spr(wbc_spr.wb_channel),
	.c_msr(wbc_msr.wb_channel),

	.res(resbus.write_back),
	.reg_read(register_file_if.reg_file),
	.gpr_file(gpr_file_if.processor),
	.timer(timer_i.write_back)
);

/*Bypass #(.ENABLE_FORWARDING(OPT_FORWARDING)) bypass
	(	.ctrl(bypass_if.bypass),
		.fixedpoint(fixedpoint_data.bypass),
		.load_store(load_store_data.bypass),
		.write_back(write_back_data.bypass) );*/

Int_sched int_sched (
	.clk(clk),
	.reset(reset),
	.intf(int_sched_if.int_sched),
	.reg_file(register_file_if.int_sched),
	.timer(timer_i.int_sched),
	.ictrl(interrupt_control)
);

Gpr_file #(
	.SINGLE_WRITE_PORT(1'b1)
) gpr_file (
	.clk(clk),
	.reset(reset),
	.intf(gpr_file_if.gpr_file)
);

assign register_file_if.gin_in = gin;
assign gout = register_file_if.gout;
assign goe = register_file_if.goe;

assign
	frontend_control.wakeup = ctrl.wakeup;
assign
	int_sched_if.base_doorbell = ctrl.doorbell,
	int_sched_if.base_ext_input = ctrl.ext_input,
	ctrl.ext_input_ack = int_sched_if.base_ext_input_ack,
	ctrl.doorbell_ack = int_sched_if.base_doorbell_ack,
	ctrl.other_ack = int_sched_if.other_ack;

assign
	ctrl.iccr = register_file_if.iccr,
	ctrl.msr_ee = register_file_if.msr.ee;

assign ctrl.mon_hold_dc = 1'b0;

endmodule

// vim: noexpandtab ts=4 sw=4 softtabstop=0 nosmarttab:
