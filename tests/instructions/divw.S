# See LICENSE for license details.

#*****************************************************************************
# divw.S
#----------------------------------------------------------------------------- # # Test div instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Arithmetic tests
#-------------------------------------------------------------

TEST_RR_OP( 2, divw,  3,  20,   6 ) ;
TEST_RR_OP( 3, divw, -3, -20,   6 ) ;
TEST_RR_OP( 4, divw, -3,  20,  -6 ) ;
TEST_RR_OP( 5, divw,  3, -20,  -6 ) ;

TEST_RR_OP( 6, divw, -1<<63, -1<<63,  1 ) ;
TEST_RR_OP( 7, divw, -1<<63, -1<<63, -1 ) ;

TEST_RR_OP( 8, divw, -1, -1<<63, 0 ) ;
TEST_RR_OP( 9, divw, -1,      1, 0 ) ;
TEST_RR_OP(10, divw, -1,      0, 0 ) ;

TEST_PASSFAIL

PPCTEST_CODE_END

.data
PPCTEST_DATA_BEGIN

TEST_DATA

PPCTEST_DATA_END
