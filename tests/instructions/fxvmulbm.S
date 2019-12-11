# See LICENSE for license details.

#*****************************************************************************
# fxvmulbm.S
#-----------------------------------------------------------------------------
#
# Test fxvmulbm instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Basic tests
#-------------------------------------------------------------

TEST_FXV_RR_OP(2, fxvmulbm, 0, 0, 0, fxvsplatb, fxvstax, result_base) ;
TEST_FXV_RR_OP(3, fxvmulbm, 0x01010101, 1, 1, fxvsplatb, fxvstax, result_base) ;
TEST_FXV_RR_OP(4, fxvmulbm, 0x15151515, 3, 7, fxvsplatb, fxvstax, result_base) ;
TEST_FXV_RR_OP(5, fxvmulbm, 0, 0x7f, 0x0, fxvsplatb, fxvstax, result_base) ;
TEST_FXV_RR_OP(6, fxvmulbm, 0x7e7e7e7e, 0x12, 0x07, fxvsplatb, fxvstax, result_base) ;
TEST_FXV_RR_OP(7, fxvmulbm, 0xffffffff, 0xff, 0x01, fxvsplatb, fxvstax, result_base) ;

TEST_PASSFAIL

PPCTEST_CODE_END

.data
PPCTEST_DATA_BEGIN

TEST_DATA

result_base:
tdat1:	  .long 0x00ff00ff
tdat2:	  .long 0xff00ff00
tdat3:	  .long 0x0ff00ff0
tdat4:	  .long 0xf00ff00f

PPCTEST_DATA_END
