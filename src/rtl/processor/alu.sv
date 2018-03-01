// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


module Alu
	(	input logic clk, reset,

		input Pu_types::Alu_op             op,
		
		input Pu_types::Word               a, b,
		input logic                        cin,
		input Pu_types::Condition_register cr,

		output Pu_types::Word              res,
		output logic                       cout,
		output Pu_types::Cr_field          crout );

import Pu_types::*;

Word      ae;  /**< Input a sign extended */

Word      adder_res;  /**< Output from the adder module */
Word      logic_res;
Word      isel_res;
Word      popcnt_res;
Word      parity_res;
Word      cntlz_res;
Word      red_res;  /**< reduced result */

Cr_field  adder_cr;
Cr_field  logic_cr;
Cr_field  crl_cr;
Cr_field  isel_cr;
Cr_field  cntlz_cr;
Cr_field  red_cr;  /**< reduced condition register field */

logic     adder_cout;
logic     red_cout;  /**< reduced carry output */

//---------------------------------------------------------------------------
// Submodules
//---------------------------------------------------------------------------

Exts exts
	(	.op(op),
		.win(a),
		.wout(ae) );

Adder adder
	(	.op(op),
		.a(a),
		.b(b),
		.cin(cin),
		.res(adder_res),
		.cout(adder_cout),
		.cr(adder_cr)
	);

Logical logical
	(	.op(op),
		.a(a),
		.b(b),
		.res(logic_res),
		.cr(logic_cr)
	);

Isel isel
	(	.op(op),
		.a(ae),
		.b(b),
		.cr(cr),
		.bc(5'b0),
		.sel_b(1'b0),
		.res(isel_res),
		.crout(isel_cr)
	);

Popcnt popcnt
	(	.x(a),
		.cnt_bytes(1'b1),
		.y(popcnt_res) );
		
Parity parity
	(	.x(a),
		.y(parity_res) );

Cntlz cntlz (
	.x(a),
	.y(cntlz_res),
	.crout(cntlz_cr)
);
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
// Reduce results
//---------------------------------------------------------------------------
always_comb begin
		unique case(op)
			Alu_add, Alu_sub, Alu_neg, Alu_cmp, Alu_cmpl: begin
				red_res = adder_res;
				red_cr = adder_cr;
				red_cout = adder_cout;
			end
			Alu_and, Alu_andc, Alu_or, Alu_orc,
			Alu_xor, Alu_nand, Alu_nor, Alu_eqv: begin
				red_res = logic_res;
				red_cr = logic_cr;
				red_cout = adder_cout;
			end

			Alu_esh, Alu_esb: begin
				red_res = isel_res;
				red_cr = isel_cr;
				red_cout = adder_cout;
			end

			Alu_popcnt: begin
				red_res = popcnt_res;
				red_cr = adder_cr;
				red_cout = adder_cout;
			end

			Alu_prty: begin
				red_res = parity_res;
				red_cr = adder_cr;
				red_cout = adder_cout;
			end
			Alu_cntlz: begin
				red_res = cntlz_res;
				red_cr = cntlz_cr;
				red_cout = adder_cout;
			end
			default: begin
				red_res = adder_res;
				red_cr = adder_cr;
				red_cout = adder_cout;
			end
		endcase
	end
//---------------------------------------------------------------------------



//---------------------------------------------------------------------------
// connections to output interfaces
//---------------------------------------------------------------------------
assign
	res = red_res,
	cout = red_cout,
	crout = red_cr;
//---------------------------------------------------------------------------
	
endmodule
