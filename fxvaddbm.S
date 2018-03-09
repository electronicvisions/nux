# See LICENSE for license details.

#*****************************************************************************
# fxvaddbm.S
#-----------------------------------------------------------------------------
#
# Test fxvaddbm instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Basic tests
#-------------------------------------------------------------

TEST_FXV_RR_OP(2, fxvaddbm, 0, 0, 0, fxvsplatb, fxvstax, result_base) ;
TEST_FXV_RR_OP(3, fxvaddbm, 0x02020202, 1, 1, fxvsplatb, fxvstax, result_base) ;
TEST_FXV_RR_OP(4, fxvaddbm, 0x0a0a0a0a, 3, 7, fxvsplatb, fxvstax, result_base) ;
TEST_FXV_RR_OP(5, fxvaddbm, 0xffffffff, 0xfe, 1, fxvsplatb, fxvstax, result_base) ;

#-------------------------------------------------------------
# Vector store
#-------------------------------------------------------------

# TEST_FXV_RR_OP(6, fxvaddbm, 0x0a0a0a0a, 3, 7, fxvsplatb, fxvoutx, (1<<29)) ;


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
