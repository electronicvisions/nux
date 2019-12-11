# See LICENSE for license details.

#*****************************************************************************
# divwu.S
#-----------------------------------------------------------------------------
#
# Test divwu instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Arithmetic tests
#-------------------------------------------------------------

TEST_RR_OP( 2, divwu,                   3,  20,   6 ) ;
TEST_RR_OP( 3, divwu,           715827879, -20,   6 ) ;
TEST_RR_OP( 4, divwu,                   0,  20,  -6 ) ;
TEST_RR_OP( 5, divwu,                   0, -20,  -6 ) ;

TEST_RR_OP( 6, divwu, -1<<31, -1<<31,  1 ) ;
TEST_RR_OP( 7, divwu,     0,  -1<<31, -1 ) ;

TEST_RR_OP( 8, divwu, -1, -1<<31, 0 ) ;
TEST_RR_OP( 9, divwu, -1,      1, 0 ) ;
TEST_RR_OP(10, divwu, -1,      0, 0 ) ;

TEST_PASSFAIL

PPCTEST_CODE_END

.data
PPCTEST_DATA_BEGIN

TEST_DATA

PPCTEST_DATA_END
