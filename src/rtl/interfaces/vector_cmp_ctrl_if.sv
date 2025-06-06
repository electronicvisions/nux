// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


interface Vector_cmp_ctrl_if();

  Valu_pkg::Valu_type elem_type;

  modport ctrl (
    output elem_type
  );

  modport cmp (
    input elem_type
  );

endinterface

/* vim: set et fenc= ff=unix sts=0 sw=2 ts=2 : */


