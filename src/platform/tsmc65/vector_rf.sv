// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


module Vector_rf
  #(parameter int NUM_ELEMS = 8,
    parameter int ELEM_SIZE = 16,
    parameter int ENABLES_PER_ELEMENT = 4,
    parameter int VRF_SIZE = 32)
  ( input logic clk, reset,
    input logic en,
    input logic[0:ENABLES_PER_ELEMENT - 1] write_mask[0:NUM_ELEMS-1],
    input logic[$clog2(VRF_SIZE)-1:0] addr,
    input logic we,
    output logic[NUM_ELEMS*ELEM_SIZE-1:0] data_r,
    input logic[NUM_ELEMS*ELEM_SIZE-1:0] data_w
  );

  //--------------------------------------------------------------------------------
  // Local types
  //--------------------------------------------------------------------------------

  localparam int SUB_ELEMENT_SIZE = ELEM_SIZE / ENABLES_PER_ELEMENT;

  typedef logic[NUM_ELEMS*ELEM_SIZE-1:0] Vector_raw;

  //--------------------------------------------------------------------------------
  // Local signals
  //--------------------------------------------------------------------------------

  Vector_raw bweb, write_bit_mask;

  //--------------------------------------------------------------------------------
  // Processes
  //--------------------------------------------------------------------------------

  always_comb begin
    for(int i=0; i<NUM_ELEMS; i++) begin
      for(int j=0; j<ENABLES_PER_ELEMENT; j++) begin
        write_bit_mask[$left(write_bit_mask) - i*ELEM_SIZE - j*SUB_ELEMENT_SIZE -: SUB_ELEMENT_SIZE] = {SUB_ELEMENT_SIZE{write_mask[i][j]}};
      end
    end
  end

  assign bweb = ~write_bit_mask;

  TS5N65LPA32X128M2 sram (
    .CLK(clk),
    .CEB(~en),
    .WEB(~we),
    .A(addr),
    .D(data_w),
    .BWEB(bweb),
    .Q(data_r)
  );


`ifndef SYNTHESIS

  initial begin
    assert(NUM_ELEMS * ELEM_SIZE == 128) else
      $error("replace macro if you want to use a different register width than 128 bits");
  end

`endif  /* SYNTHESIS */

endmodule

/* vim: set et fenc= ff=unix sts=0 sw=2 ts=2 : */
