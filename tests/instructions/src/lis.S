# See LICENSE for license details.

#*****************************************************************************
# lis.S
#-----------------------------------------------------------------------------
#
# Test lis instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  TEST_CASE( 2, %r1, 0x0000000000000000, lis %r1, 0x00000 );
  TEST_CASE( 3, %r1, 0xffffffffffff8000, lis %r1, 0xffff;srawi %r1,%r1,1);
  TEST_CASE( 4, %r1, 0x00000000000007ff, lis %r1, 0x7fff;srawi %r1,%r1,16+4);
  TEST_CASE( 5, %r1, 0xfffffffffffff800, lis %r1, 0x8000;srawi %r1,%r1,16+4);

  //TEST_CASE( 6, %r0, 0, lis %r0, 0x8000 );

  TEST_PASSFAIL

PPCTEST_CODE_END

  .data
PPCTEST_DATA_BEGIN

  TEST_DATA

PPCTEST_DATA_END
