// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


module Fixedpoint
	#(	parameter bit WITH_MULTIPLIER = 1'b1,
		parameter bit WITH_DIVIDER = 1'b1 )
	(	input logic clk, reset,

		Fixedpoint_ctrl_if.internal  ctrl,
		Fixedpoint_data_if.execute   data,
		input logic                  so,
		output Backend::Result_bus            result );

import Pu_types::*;
import Backend::Result_bus;


// internal signals
Word     alu_res;
logic    alu_cout;
Cr_field alu_crf;
	
Word     rotm_res;
logic    rotm_cout;
Cr_field rotm_crf;

Word     spreu_res;
//Cr_field spreu_crf;
Condition_register spreu_cr;

Word     mul_res_hi, mul_res_lo;
Cr_field mul_crf_hi, mul_crf_lo;

Word     div_res;
Cr_field div_crf;

Word     res;
Condition_register res_b;
logic    cout;
Cr_field crf;

Word     spreu_sprout;
Msr      spreu_msrout, spreu_msrout_d;
//---------------------------------------------------------------------------
// function sub-units
// each of these should have its own output registers.
// TODO connect outputs from FUs to bypass network
Alu alu
	(	.clk(clk),
		.reset(reset),
		.op(ctrl.alu_op),
		.a(data.alu_a_out),
		.b(data.alu_b_out),
		.cin(data.alu_cin),
		.cr(data.alu_cr_out),
		
		.res(alu_res),
		.cout(alu_cout),
		.crout(alu_crf) );

// rotate left and mask  
Rotm rotm
	(	.clk(clk),
		.reset(reset),
		.x(data.rotm_x_out),
		.q(data.rotm_q_out),
		.num(data.rotm_sh),
		.mstart(data.rotm_ma),
		.mstop(data.rotm_mb),

		.y(rotm_res),
		.cout(rotm_cout),
		.cr(rotm_crf) );

// special purpose register execution unit
Spreu spreu
	(	.clk(clk), .reset(reset),
		.cr_op(ctrl.cr_op),
		.sel_a(ctrl.crl_ba),
		.sel_b(ctrl.crl_bb),
		.sel_t(ctrl.crl_bt),
		.reg_mv(ctrl.reg_mv),
		.src_cr(ctrl.src_cr),
		.a(data.spreu_a_out),
		.sprin(data.spreu_sprin),
		.crin(data.spreu_cr_out),
		.msrin(data.spreu_msrin),
		
		.res(spreu_res),
		.crout(spreu_cr),
		.sprout(spreu_sprout),
		.msrout(spreu_msrout) );

generate if( WITH_MULTIPLIER ) begin : gen_mul
	// using DesignWare multiplier
	Mul_dw_seq mul
	//Mul_dw_pipe mul
		(	.clk(clk),
			.reset(reset),
			.en(ctrl.mul_en),
			.uns(ctrl.mul_unsigned),

			.a(data.mul_a_out),
			.b(data.mul_b_out),
			
			.ready(ctrl.mul_ready),
			.complete(ctrl.mul_complete),
			.res_hi(mul_res_hi),
			.res_lo(mul_res_lo),
			.crf_hi(mul_crf_hi),
			.crf_lo(mul_crf_lo) );
end : gen_mul
else
begin : gen_nomul
	assign
		mul_res_hi = '0,
		mul_res_lo = '0,
		mul_crf_hi = '0,
		mul_crf_lo = '0;
end : gen_nomul
endgenerate

generate
	if( WITH_DIVIDER ) begin : gen_div
		Div_dw_seq div
			(	.clk(clk),
				.reset(reset),
				.en(ctrl.div_en),
				.uns(ctrl.div_unsigned),

				.a(data.div_a_out),
				.b(data.div_b_out),
				.crf(div_crf),

				.ready(ctrl.div_ready),
				.complete(ctrl.div_complete),
				.quotient(div_res),
				.remainder(),
				.div_by_zero() );
	end : gen_div
	else
	begin : gen_nodiv
		assign
			div_res = '0,
			div_crf = '0;
	end : gen_nodiv
endgenerate

//---------------------------------------------------------------------------
// use the second cycle parallel to load/store to reduce the result for
// write back
always_comb
begin
	case(ctrl.sel_d)
		Fu_alu:     res = alu_res;
		Fu_rotm:    res = rotm_res;
		Fu_spreu:   res = spreu_res;
		Fu_mul:     res = ctrl.mul_high_d ? mul_res_hi : mul_res_lo; 
		Fu_div:     res = div_res;
		default:    res = 'x;
	endcase

	case(ctrl.sel_d)
		Fu_alu: begin
			//res_b = data.alu_cr_out;
			res_b = '0;
			res_b[ctrl.crl_bt_d[4:2]] = alu_crf;
			res_b[ctrl.crl_bt_d[4:2]].ov = so | (ctrl.oe_d & crf.ov);
		end
		Fu_spreu:   res_b = spreu_cr;
		default:    res_b = '0;
	endcase

	case(ctrl.sel_d)
		Fu_alu:     crf = alu_crf;
		Fu_rotm:    crf = rotm_crf;
		Fu_spreu:   crf = spreu_cr[0];
		Fu_mul:     crf = ctrl.mul_high_d ? mul_crf_hi : mul_crf_lo;
		Fu_div:     crf = div_crf;
		default:    crf = 'x;
	endcase
		
	case(ctrl.sel_d)
		Fu_alu:     cout = alu_cout;
		Fu_rotm:    cout = rotm_cout;
		Fu_spreu:   cout = 1'b0;
		Fu_mul:     cout = 1'b0;
		Fu_div:     cout = 1'b0;
		default:    cout = 1'bx;
	endcase
end
//---------------------------------------------------------------------------
assign data.res = res;

//---------------------------------------------------------------------------
generate
	if( Frontend::default_latency == 2 ) begin : gen_normal_latency

		assign result.valid = 1'b1;

		always_ff @(posedge clk or posedge reset)
		begin
		   if( reset ) begin
			result.res_a <= '0;
			result.res_b <= '0;
			result.cout <= 1'b0;
			result.crf <= '0;
			result.msr <= '0;
			result.ov <= 1'b0;
		   end else begin
			result.res_a <= res;
			result.res_b <= res_b;
			result.cout <= cout;
			result.crf <= crf;
			if( ctrl.sel_d != Fu_spreu )
				result.crf.ov <= so | (ctrl.oe_d & crf.ov);
			result.ov <= crf.ov;
			result.msr <= spreu_msrout;
		   end
		end
	end : gen_normal_latency
	else if( Frontend::default_latency == 1 ) begin : gen_low_latency

		assign result.valid = 1'b1;

		always_comb begin
			result.res_a = res;
			result.res_b = res_b;
			result.cout = cout;
			result.crf = crf;
			if( ctrl.sel_d != Fu_spreu )
				result.crf.ov = so | (ctrl.oe_d & crf.ov);
			result.ov = crf.ov;
			result.msr = spreu_msrout;
		end

	end : gen_low_latency
endgenerate
//---------------------------------------------------------------------------

endmodule

