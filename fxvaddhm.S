# See LICENSE for license details.

#*****************************************************************************
# fxvaddhm.S
#-----------------------------------------------------------------------------
#
# Test fxvaddhm instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Basic tests
#-------------------------------------------------------------

TEST_FXV_RR_OP(2, fxvaddhm, 0, 0, 0, fxvsplath, fxvstax, result_base) ;
TEST_FXV_RR_OP(3, fxvaddhm, 0x2, 1, 1, fxvsplath, fxvstax, result_base) ;
TEST_FXV_RR_OP(4, fxvaddhm, 0xa, 3, 7, fxvsplath, fxvstax, result_base) ;
TEST_FXV_RR_OP(5, fxvaddhm, 0xffff, 0x7fff, 0x8000, fxvsplath, fxvstax, result_base) ;
TEST_FXV_RR_OP(6, fxvaddhm, 0xffff, 0xfffe, 0x0001, fxvsplath, fxvstax, result_base) ;

TEST_PASSFAIL

PPCTEST_CODE_END

PPCTEST_DATA_BEGIN

TEST_DATA

result_base:
tdat1:	  .long 0x00ff00ff
tdat2:	  .long 0xff00ff00
tdat3:	  .long 0x0ff00ff0
tdat4:	  .long 0xf00ff00f

PPCTEST_DATA_END
