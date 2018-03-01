// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


module Write_back
  ( input logic clk, reset,

    Wb_channel_if.wb_channel c_gpr,
    Wb_channel_if.wb_channel c_cr,
    Wb_channel_if.wb_channel c_xer,
    Wb_channel_if.wb_channel c_lnk,
    Wb_channel_if.wb_channel c_ctr,
    Wb_channel_if.wb_channel c_spr,
    Wb_channel_if.wb_channel c_msr,

    Result_if.write_back res,
    Register_file_if.reg_file reg_read,
    Gpr_file_if.processor gpr_file,
    Timer_if.write_back timer );

import Pu_types::*;
import Pu_interrupt::*;
import Backend::*;
import Frontend::*;


//---------------------------------------------------------------------------
// Local signals and types
//---------------------------------------------------------------------------

Condition_register  cr;
Word                ctr;
Word                lnk;
Xer                 xer;
logic[28:0]         xer_padding;
Msr                 msr;
Esr                 esr;
Word                srr0, srr1;
Word                csrr0, csrr1;
Word                mcsrr0, mcsrr1;
Word                dear;
Int_ctrl_reg        iccr;
Word                gout;
Word                goe;
Word                gin;

logic[7:0]          cr_sel;
logic               cr_multi_field;
//---------------------------------------------------------------------------
// Local functions
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
function automatic Word get_res_a(Fu_set s);
  Fu_set_id id;
  Result_bus b;

  id = Frontend::fu_set_id(s);
  b = res.get_res(id);
  return b.res_a;
endfunction
//---------------------------------------------------------------------------
function automatic Word get_res_b(Fu_set s);
  Fu_set_id id;
  Result_bus b;

  id = Frontend::fu_set_id(s);
  b = res.get_res(id);
  return b.res_b;
endfunction
//---------------------------------------------------------------------------
function automatic Condition_register get_crf(Fu_set s);
  Fu_set_id id;
  Result_bus b;

  id = Frontend::fu_set_id(s);
  b = res.get_res(id);
  return b.crf;
endfunction
//---------------------------------------------------------------------------
function automatic logic get_cout(Fu_set s);
  Fu_set_id id;
  Result_bus b;

  id = Frontend::fu_set_id(s);
  b = res.get_res(id);
  return b.cout;
endfunction
//---------------------------------------------------------------------------
function automatic logic get_crf_ov(Fu_set s);
  Fu_set_id id;
  Result_bus b;

  id = Frontend::fu_set_id(s);
  b = res.get_res(id);
  return b.crf.ov;
endfunction
//---------------------------------------------------------------------------
function automatic logic get_ov(Fu_set s);
  Fu_set_id id;
  Result_bus b;

  id = Frontend::fu_set_id(s);
  b = res.get_res(id);
  return b.ov;
endfunction
//---------------------------------------------------------------------------
function automatic Msr get_msr(Fu_set s);
  Fu_set_id id;
  Result_bus b;

  id = Frontend::fu_set_id(s);
  b = res.get_res(id);
  return b.msr;
endfunction
//---------------------------------------------------------------------------
function automatic logic get_valid(Fu_set s);
  Fu_set_id id;
  Result_bus b;

  id = Frontend::fu_set_id(s);
  b = res.get_res(id);
  return b.valid;
endfunction
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
// GPR write back channel
//---------------------------------------------------------------------------

assign
  gpr_file.ra_sel = reg_read.gpr_sel_a,
  gpr_file.rb_sel = reg_read.gpr_sel_b,
  gpr_file.rc_sel = reg_read.gpr_sel_c,
  reg_read.gpr_a = gpr_file.ra,
  reg_read.gpr_b = gpr_file.rb,
  reg_read.gpr_c = gpr_file.rc;

always_comb begin
  gpr_file.wa_sel = c_gpr.dest;
  gpr_file.wa_wr = c_gpr.we & get_valid(c_gpr.src);
  gpr_file.wa = get_res_a(c_gpr.src);
  // not used at the moment so tie them to zero...
  gpr_file.wb_sel = '0;
  gpr_file.wb = '0;
  gpr_file.wb_wr = '0;

  // $display("gpr_file.wa = get_res_a(%s) <- %08h", Frontend::fu_set_to_string(c_gpr.src), get_res_a(c_gpr.src));
end

//---------------------------------------------------------------------------
// Some special purpose register channels channel
//---------------------------------------------------------------------------

assign cr_sel = c_cr.dest;


assign
  reg_read.cr = Cr_bits'(cr),
  reg_read.ctr = ctr,
  reg_read.lnk = lnk,
  reg_read.xer = {xer, 29'b0};

// a non-resettable register file improves performance.
// synchronous reset seems to be just as good.
//always_ff @(posedge clk [>or posedge reset<])
always_ff @(posedge clk or posedge reset)
begin : writer
  if( reset ) begin
    cr  <= '0;
    ctr <= '0;
    lnk <= '0;
    xer <= '0;
  end else begin
    if( c_cr.we && get_valid(c_cr.src) ) begin
      if( cr_sel[0] == 1'b1 )
	cr[0] <= get_crf(c_cr.src);

      for(int i=1; i<8; i++)
	if( cr_sel[i] == 1'b1 ) begin
	  Condition_register res_b;
	  res_b = Condition_register'(get_res_b(c_cr.src));
	  cr[i] <= res_b[i];
	end
    end

    if( c_spr.we && (c_spr.dest == Spr_ctr) && get_valid(c_spr.src) )
      ctr <= get_res_a(c_spr.src);
    else if( c_ctr.we && get_valid(c_spr.src) ) begin
      ctr <= get_res_a(c_ctr.src);
    end

    if( c_spr.we && (c_spr.dest == Spr_lnk) && get_valid(c_spr.src) )
	lnk <= get_res_a(c_spr.src);
    else if( c_lnk.we && get_valid(c_lnk.src) ) begin
      if( c_lnk.src == FUB_BRANCH )
	lnk <= get_res_b(FUB_BRANCH);
      else
	lnk <= get_res_a(c_lnk.src);
    end

    if( c_spr.we && (c_spr.dest == Spr_xer) && get_valid(c_spr.src) )
      {xer, xer_padding} <= get_res_a(c_spr.src);
    else if( c_xer.we && get_valid(c_xer.src) ) begin
      if( c_xer.dest == XER_DEST_ALL )
	{xer, xer_padding} <= get_res_a(c_xer.src);
      else if( c_xer.dest == XER_DEST_CA )
	xer.ca <= get_cout(c_xer.src);
      else if( c_xer.dest == XER_DEST_OV ) begin
	xer.ov <= get_ov(c_xer.src);
	xer.so <= get_ov(c_xer.src) | xer.so;
      end else if( c_xer.dest == XER_DEST_CA_OV ) begin
	xer.ca <= get_cout(c_xer.src);
	xer.ov <= get_ov(c_xer.src);
	xer.so <= get_ov(c_xer.src) | xer.so;
      end
    end
  end
end : writer


//---------------------------------------------------------------------------
// Machine state and interrupt reigster channels
//---------------------------------------------------------------------------

/** Some bits in MSR and ESR are set to fixed or undefined values */
always_comb
begin
	reg_read.msr = msr;

  // XXX
  reg_read.msr.comp_mode = 1'b0;  // always in 32bit mode
  reg_read.msr.pr = 1'b0;         // always privileged
  reg_read.msr.fp = 1'b0;         // no floating point
  reg_read.msr.reserved0 = '0;
  reg_read.msr.reserved1 = '0;
  reg_read.msr.reserved2 = '0;
  reg_read.msr.reserved3 = '0;
  reg_read.msr.reserved4 = '0;


	reg_read.esr = esr;

  // XXX
  reg_read.esr.dlk = '0;
  reg_read.esr.reserved0 = '0;
  reg_read.esr.reserved1 = '0;
  reg_read.esr.reserved2 = '0;
  reg_read.esr.reserved3 = '0;
  reg_read.esr.reserved4 = '0;
end

assign
  reg_read.srr0 = srr0,
  reg_read.srr1 = srr1,
  reg_read.csrr0 = csrr0,
  reg_read.csrr1 = csrr1,
  reg_read.mcsrr0 = mcsrr0,
  reg_read.mcsrr1 = mcsrr1,
  reg_read.iccr = iccr,
  reg_read.dear = dear;


//always_ff @(posedge clk)
always_ff @(posedge clk or posedge reset)
	if( reset ) begin
		msr <= '0;
		esr <= '0;
		srr0 <= '0;
		srr1 <= '0;
		csrr0 <= '0;
		csrr1 <= '0;
		mcsrr0 <= '0;
		mcsrr1 <= '0;
		dear <= '0;
	end else begin
		if( c_msr.we && get_valid(c_msr.src) )
			msr <= get_msr(c_msr.src);
		else if( reg_read.msr_we )
			msr <= reg_read.msr_in;

		// overwrite reserved or unimplemented values
    // XXX this generates flops with async set and reset
    msr.comp_mode <= 1'b0;  // always in 32bit mode
    msr.pr <= 1'b0;         // always privileged
    msr.fp <= 1'b0;         // no floating point
    msr.reserved0 <= '0;
    msr.reserved1 <= '0;
    msr.reserved2 <= '0;
    msr.reserved3 <= '0;
    msr.reserved4 <= '0;

		if( c_spr.we && (c_spr.dest == Spr_esr) && get_valid(c_spr.src) )
			esr <= get_res_a(c_spr.src);
		else if( reg_read.esr_we )
			esr <= reg_read.esr_in;

		// overwrite reserved values
    // XXX this generates flops with async set and reset
    esr.dlk <= '0;
    esr.reserved0 <= '0;
    esr.reserved1 <= '0;
    esr.reserved2 <= '0;
    esr.reserved3 <= '0;
    esr.reserved4 <= '0;

		if( c_spr.we && (c_spr.dest == Spr_dear) && get_valid(c_spr.src) )
			dear <= get_res_a(c_spr.src);
		else if( reg_read.dear_we )
			dear <= reg_read.dear_in;

		if( c_spr.we && (c_spr.dest == Spr_srr0) && get_valid(c_spr.src) )
			srr0 <= get_res_a(c_spr.src);
		else if( reg_read.srr_we )
			srr0 <= reg_read.srr0_in;

		if( c_spr.we && (c_spr.dest == Spr_srr1) && get_valid(c_spr.src) )
			srr1 <= get_res_a(c_spr.src);
		else if( reg_read.srr_we )
			srr1 <= reg_read.srr1_in;

		if( c_spr.we && (c_spr.dest == Spr_csrr0) && get_valid(c_spr.src) )
			csrr0 <= get_res_a(c_spr.src);
		else if( reg_read.csrr_we )
			csrr0 <= reg_read.csrr0_in;

		if( c_spr.we && (c_spr.dest == Spr_csrr1) && get_valid(c_spr.src) )
			csrr1 <= get_res_a(c_spr.src);
		else if( reg_read.csrr_we )
			csrr1 <= reg_read.csrr1_in;

		if( c_spr.we && (c_spr.dest == Spr_mcsrr0) && get_valid(c_spr.src) )
			mcsrr0 <= get_res_a(c_spr.src);
		else if( reg_read.mcsrr_we )
			mcsrr0 <= reg_read.mcsrr0_in;

		if( c_spr.we && (c_spr.dest == Spr_mcsrr1) && get_valid(c_spr.src) )
			mcsrr1 <= get_res_a(c_spr.src);
		else if( reg_read.mcsrr_we )
			mcsrr1 <= reg_read.mcsrr1_in;
	end

always_ff @(posedge clk or posedge reset)
	if( reset )
		iccr <= '0;
	else
		if( c_spr.we && (c_spr.dest == Spr_iccr) && get_valid(c_spr.src) )
			iccr <= get_res_a(c_spr.src);

//---------------------------------------------------------------------------
// Timer facility channel
//---------------------------------------------------------------------------

always_comb begin
  timer.tbu_in = get_res_a(c_spr.src);
  timer.tbl_in = get_res_a(c_spr.src);
  timer.dec_in = get_res_a(c_spr.src);
  timer.decar_in = get_res_a(c_spr.src);
  timer.tcr_in = get_res_a(c_spr.src);
  timer.tsr_in = get_res_a(c_spr.src);
end

always_comb begin
  timer.tbu_we = (c_spr.dest == Spr_tbu) && get_valid(c_spr.src);
  timer.tbl_we = (c_spr.dest == Spr_tbl) && get_valid(c_spr.src);
  timer.dec_we = (c_spr.dest == Spr_dec) && get_valid(c_spr.src);
  timer.decar_we = (c_spr.dest == Spr_decar) && get_valid(c_spr.src);
  timer.tcr_we = (c_spr.dest == Spr_tcr) && get_valid(c_spr.src);
  timer.tsr_we = (c_spr.dest == Spr_tsr) && get_valid(c_spr.src);
end


//---------------------------------------------------------------------------
// General-purpose IO registers
//---------------------------------------------------------------------------

always_ff @(posedge clk or posedge reset)
  if( reset ) begin
    goe <= 'b0;
    gout <= 'b0;
    gin <= 'b0;
  end else begin
    if( c_spr.we && c_spr.dest == Spr_goe  && get_valid(c_spr.src))
      goe <= get_res_a(c_spr.src);

    if( c_spr.we && c_spr.dest == Spr_gout  && get_valid(c_spr.src))
      gout <= get_res_a(c_spr.src);

    gin <= reg_read.gin_in;
  end

assign
  reg_read.gin = gin,
  reg_read.gout = gout,
  reg_read.goe = goe;


endmodule



//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------

//module Write_back
	//#(	parameter bit SINGLE_WRITE_PORT = 1'b0 )
	//(	input logic clk,
		//input logic reset,

		//Write_back_ctrl_if.write_back  ctrl,
		//Write_back_data_if.write_back  data,
		//Register_file_if.write         register_file,
		//Timer_if.pu                    timer,
		//output logic                   sleep );

//logic    pr_cr_wr;  // priority CR write from register to register transfers
//logic    pr_gpr_wr; // priority write to GPR
//logic    pr_xer_wr;
//logic    pr_ctr_wr;
//logic    pr_lnk_wr;

//// WORKAROUND for synplify
//Condition_register register_file_cr;
//assign register_file_cr = register_file.cr;

//assign register_file.wr_cr = ctrl.wb_record_cr & {$bits(ctrl.wb_record_cr){ctrl.en}};

////assign inst_fetch.new_pc = data.res;
////assign inst_fetch.jump = data.wb_jump;


////---------------------------------------------------------------------------
//generate
	//if( SINGLE_WRITE_PORT == 1'b0 ) begin : gen_write_port
		//assign register_file.gpr_sel_dest = ctrl.wb_gpr_dest_alu;
		//assign register_file.gpr_sel_dest_2 = ctrl.wb_gpr_dest_mem;
		////---------------------------------------------------------------------------
		//// Multiplex GPR writeback lines
		////---------------------------------------------------------------------------
		//assign register_file.gpr_dest = data.res;
		//assign register_file.gpr_dest_2 = data.dout;

		////---------------------------------------------------------------------------
		//// Set GPR writeback enables
		////---------------------------------------------------------------------------
		//assign register_file.gpr_we = ctrl.wb_gpr_wr_alu & ctrl.en;
		//assign register_file.gpr_we_2 = ctrl.wb_gpr_wr_mem & ctrl.en;
	//end else begin
		//always_comb begin
			//if( ctrl.wb_gpr_wr_mem ) begin
				//register_file.gpr_dest = data.dout;
				//register_file.gpr_sel_dest = ctrl.wb_gpr_dest_mem;
			//end else begin
				//register_file.gpr_dest = data.res;
				//register_file.gpr_sel_dest = ctrl.wb_gpr_dest_alu;
			//end
		//end

		//assign register_file.gpr_we = (ctrl.wb_gpr_wr_alu | ctrl.wb_gpr_wr_mem) & ctrl.en;
	//end
//endgenerate
////---------------------------------------------------------------------------

////---------------------------------------------------------------------------
//// Control writeback to CR
////---------------------------------------------------------------------------
//always_comb
//begin : write_cr
	//if( ctrl.wb_wr_cr )
		//register_file.cr_in = data.wb_cr;
	//else begin
		//Cr_field cr;
		//cr = data.wb_cr;
		//if( ctrl.wb_record_ov )
			//cr.ov = data.wb_cr.ov | register_file.xer[31];  // copy of SO bit from XER
		//else
			//cr.ov = register_file.xer[31];
		//register_file.cr_in = cr;
	//end
//end : write_cr

////---------------------------------------------------------------------------
//// Control writeback to XER
////---------------------------------------------------------------------------
//always_comb
//begin : ctrl_xer
	//// default assignment
	//register_file.xer_we = 1'b0;
	//register_file.xer_in = 'x;

	//if( ctrl.en ) begin
		//if( pr_xer_wr ) begin
			//register_file.xer_we = 1'b1;
			//register_file.xer_in = data.wb_spr;
		//end else begin
			//register_file.xer_we = ctrl.wb_record_ca | ctrl.wb_record_ov;

			//register_file.xer_in = register_file.xer;

			//if( ctrl.wb_record_ca )
				//register_file.xer_in[29] = data.cout;  // CA bit

			//if( ctrl.wb_record_ov ) begin
				//register_file.xer_in[30] = data.wb_cr.ov;  // OV bit
				//register_file.xer_in[31] = data.wb_cr.ov | register_file.xer[31];  // SO bit
			//end
		//end
	//end
//end : ctrl_xer

////---------------------------------------------------------------------------
//// Control writeback of LNK and CTR
////---------------------------------------------------------------------------
//assign register_file.ctr_we = (data.wb_ctr_we | pr_ctr_wr) & ctrl.en;
//assign register_file.lnk_we = (data.wb_lnk_we | pr_lnk_wr) & ctrl.en;

//always_comb
	//if( pr_ctr_wr )
		//register_file.ctr_in = data.wb_spr;
	//else
		//register_file.ctr_in = data.wb_ctr;

//always_comb
	//if( pr_lnk_wr )
		//register_file.lnk_in = data.wb_spr;
	//else
		//register_file.lnk_in = data.wb_lnk;

////---------------------------------------------------------------------------
//// Control writeback of MSR
////---------------------------------------------------------------------------
//always_comb
//begin
	//register_file.msr_pin = data.msr;
	//register_file.msr_pwe = ctrl.wb_msr_we & ctrl.en;
//end

////---------------------------------------------------------------------------
//always_comb
//begin
	//// default assignments
	//pr_xer_wr = 1'b0;
	//pr_ctr_wr = 1'b0;
	//pr_lnk_wr = 1'b0;
	//register_file.gout_we    = 1'b0;
	//register_file.goe_we     = 1'b0;
	//register_file.srr0_pwe   = 1'b0;
	//register_file.srr1_pwe   = 1'b0;
	//register_file.csrr0_pwe  = 1'b0;
	//register_file.csrr1_pwe  = 1'b0;
	//register_file.mcsrr0_pwe = 1'b0;
	//register_file.mcsrr1_pwe = 1'b0;
	//register_file.esr_pwe    = 1'b0;
	//register_file.dear_pwe   = 1'b0;
	//register_file.iccr_we    = 1'b0;
	//timer.tbu_we   = 1'b0;
	//timer.tbl_we   = 1'b0;
	//timer.dec_we   = 1'b0;
	//timer.decar_we = 1'b0;
	//timer.tcr_we   = 1'b0;
	//timer.tsr_we   = 1'b0;

	//// datapath assignments
	//register_file.srr0_pin    = data.wb_spr;
	//register_file.srr1_pin    = data.wb_spr;
	//register_file.csrr0_pin   = data.wb_spr;
	//register_file.csrr1_pin   = data.wb_spr;
	//register_file.mcsrr0_pin  = data.wb_spr;
	//register_file.mcsrr1_pin  = data.wb_spr;
	//register_file.dear_pin    = data.wb_spr;
	//register_file.esr_pin     = data.wb_spr;
	//register_file.gout_in     = data.wb_spr;
	//register_file.goe_in      = data.wb_spr;
	//register_file.iccr_in     = data.wb_spr;
	//timer.tbu_in   = data.wb_spr;
	//timer.tbl_in   = data.wb_spr;
	//timer.dec_in   = data.wb_spr;
	//timer.decar_in = data.wb_spr;
	//timer.tcr_in   = data.wb_spr;
	//timer.tsr_in   = data.wb_spr;

	//// select write-enable
	//if( ctrl.en ) begin
		//case(ctrl.wb_spr_sel)
			//Spr_xer:      pr_xer_wr = ctrl.wb_spr_we;
			//Spr_ctr:      pr_ctr_wr = ctrl.wb_spr_we;
			//Spr_lnk:      pr_lnk_wr = ctrl.wb_spr_we;
			//Spr_srr0:     register_file.srr0_pwe = ctrl.wb_spr_we;
			//Spr_srr1:     register_file.srr1_pwe = ctrl.wb_spr_we;
			//Spr_csrr0:    register_file.csrr0_pwe = ctrl.wb_spr_we;
			//Spr_csrr1:    register_file.csrr1_pwe = ctrl.wb_spr_we;
			//Spr_mcsrr0:   register_file.mcsrr0_pwe = ctrl.wb_spr_we;
			//Spr_mcsrr1:   register_file.mcsrr1_pwe = ctrl.wb_spr_we;
			//Spr_dear:     register_file.dear_pwe = ctrl.wb_spr_we;
			//Spr_esr:      register_file.esr_pwe = ctrl.wb_spr_we;
			//Spr_gout:     register_file.gout_we = ctrl.wb_spr_we;
			//Spr_goe:      register_file.goe_we = ctrl.wb_spr_we;
			//Spr_iccr:     register_file.iccr_we = ctrl.wb_spr_we;
			//Spr_tbu:      timer.tbu_we = ctrl.wb_spr_we;
			//Spr_tbl:      timer.tbl_we = ctrl.wb_spr_we;
			//Spr_dec:      timer.dec_we = ctrl.wb_spr_we;
			//Spr_decar:    timer.decar_we = ctrl.wb_spr_we;
			//Spr_tcr:      timer.tcr_we = ctrl.wb_spr_we;
			//Spr_tsr:      timer.tsr_we = ctrl.wb_spr_we;
		//endcase
	//end
//end

////---------------------------------------------------------------------------
//// Sleep enable register
////---------------------------------------------------------------------------

//always_ff @(posedge clk or posedge reset)
	//if( reset )
		//sleep <= 1'b0;
	//else
		//if( ctrl.en )
			//sleep <= ctrl.wb_sleep & ~ctrl.dis_sleep;


////---------------------------------------------------------------------------
//// Register to register transfers
////---------------------------------------------------------------------------
//[>always_comb
//begin : gpr_cr
	//logic[3:0] cr_field;

	//// default assignments
	//pr_cr_wr = 1'b0;
	//pr_gpr_wr = 1'b0;
	//pr_xer_wr = 1'b0;
	//pr_ctr_wr = 1'b0;
	//pr_lnk_wr = 1'b0;
	//cr_in = 4'b0;
	//gpr_dest = 32'h0;
	//pr_xer = 1'b0;
	//pr_ctr = 1'b0;
	//pr_lnk = 1'b0;
	//register_file.gout_we = 1'b0;

	//unique case(ctrl.wb_src_cr)
		//8'b10000000: cr_field = register_file_cr[0];
		//8'b01000000: cr_field = register_file_cr[1];
		//8'b00100000: cr_field = register_file_cr[2];
		//8'b00010000: cr_field = register_file_cr[3];
		//8'b00001000: cr_field = register_file_cr[4];
		//8'b00000100: cr_field = register_file_cr[5];
		//8'b00000010: cr_field = register_file_cr[6];
		//8'b00000001: cr_field = register_file_cr[7];
		//default:     cr_field = register_file_cr[0];
	//endcase


	//unique case(ctrl.wb_reg_mv)
		//Rmv_gtc: begin
			//[> variable tmp is necessary, because synplify is too stupid to
			//* understand an index select on a modport expression <]
			//Word tmp;
			//tmp = data.res;

			//// move from GPR to CR field
			//pr_cr_wr = 1'b1;
			//unique case(ctrl.wb_src_cr)
				//8'b10000000: cr_in = tmp[31:28];
				//8'b01000000: cr_in = tmp[27:24];
				//8'b00100000: cr_in = tmp[23:20];
				//8'b00010000: cr_in = tmp[19:16];
				//8'b00001000: cr_in = tmp[15:12];
				//8'b00000100: cr_in = tmp[11: 8];
				//8'b00000010: cr_in = tmp[ 7: 4];
				//8'b00000001: cr_in = tmp[ 3: 0];
				//default:     cr_in = tmp[31:28];
			//endcase
		//end

		//Rmv_ctg: begin
			//// move from CR field to field in GPR
			//pr_gpr_wr = 1'b1;
			//gpr_dest = data.res;

			//unique case(ctrl.wb_src_cr)
				//8'b10000000: gpr_dest[31:28] = cr_field;
				//8'b01000000: gpr_dest[27:24] = cr_field;
				//8'b00100000: gpr_dest[23:20] = cr_field;
				//8'b00010000: gpr_dest[19:16] = cr_field;
				//8'b00001000: gpr_dest[15:12] = cr_field;
				//8'b00000100: gpr_dest[11: 8] = cr_field;
				//8'b00000010: gpr_dest[ 7: 4] = cr_field;
				//8'b00000001: gpr_dest[ 3: 0] = cr_field;
				//default:     gpr_dest[31:28] = cr_field;
			//endcase
		//end

		//Rmv_ctc: begin
			//pr_cr_wr = 1'b1;
			//cr_in = cr_field;
		//end

		//Rmv_stg: begin
			//// move from special purpose to general purpose register
			//pr_gpr_wr = 1'b1;

			//unique casez(ctrl.wb_spr_sel)
				//Spr_xer:  gpr_dest = register_file.xer;
				//Spr_lnk:  gpr_dest = register_file.lnk;
				//Spr_ctr:  gpr_dest = register_file.ctr;
				//Spr_gin:  gpr_dest = register_file.gin;
				//Spr_gout: gpr_dest = register_file.gout;
				//default:  gpr_dest = '0;
			//endcase
		//end

		//Rmv_gts: begin
			//// move from general purpose to special purpose register

			//unique casez(ctrl.wb_spr_sel)
				//Spr_xer: begin
					//pr_xer = data.res;
					//pr_xer_wr = 1'b1;
				//end

				//Spr_ctr: begin
					//pr_ctr = data.res;
					//pr_ctr_wr = 1'b1;
				//end

				//Spr_lnk: begin
					//pr_lnk = data.res;
					//pr_lnk_wr = 1'b1;
				//end

				//Spr_gout: begin
					//register_file.gout_we = 1'b1;
				//end

				//default: begin end
			//endcase
		//end

		//default: begin
		//end
	//endcase
//end : gpr_cr*/
////---------------------------------------------------------------------------

//endmodule



// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
