# See LICENSE for license details.

#*****************************************************************************
# lhz.S
#-----------------------------------------------------------------------------
#
# Test lhz instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  TEST_LD_OP( 2, lhz, 0x00ff, 0,  tdat );
  TEST_LD_OP( 3, lhz, 0xff00, 2,  tdat );
  TEST_LD_OP( 4, lhz, 0x0ff0, 4,  tdat );
  TEST_LD_OP( 5, lhz, 0xf00f, 6, tdat );

  # Test with negative offset

  TEST_LD_OP( 6, lhz, 0x00ff, -6,  tdat4 );
  TEST_LD_OP( 7, lhz, 0xff00, -4,  tdat4 );
  TEST_LD_OP( 8, lhz, 0x0ff0, -2,  tdat4 );
  TEST_LD_OP( 9, lhz, 0xf00f,  0, tdat4 );

  # Test with a negative base

  TEST_CASE( 10, %r5, 0x00ff, \
    li  %r1, tdat; \
    addi %r1, %r1, -32; \
    lhz %r5, 32(%r1); \
  )

  # Test with unaligned base

  TEST_CASE( 11, %r5, 0xff00, \
    li  %r1, tdat; \
    addi %r1, %r1, -5; \
    lhz %r5, 7(%r1); \
  )

  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  TEST_LD_DEST_BYPASS( 12, 0, lhz, 0x0ff0, 2, tdat2 );
  TEST_LD_DEST_BYPASS( 13, 1, lhz, 0xf00f, 2, tdat3 );
  TEST_LD_DEST_BYPASS( 14, 2, lhz, 0xff00, 2, tdat1 );

  TEST_LD_SRC1_BYPASS( 15, 0, lhz, 0x0ff0, 2, tdat2 );
  TEST_LD_SRC1_BYPASS( 16, 1, lhz, 0xf00f, 2, tdat3 );
  TEST_LD_SRC1_BYPASS( 17, 2, lhz, 0xff00, 2, tdat1 );

  #-------------------------------------------------------------
  # Test write-after-write hazard
  #-------------------------------------------------------------

  TEST_CASE( 18, %r2, 2, \
    li  %r5, tdat; \
    lhz  %r2, 0(%r5); \
    li  %r2, 2; \
  )

  TEST_CASE( 19, %r2, 2, \
    li  %r5, tdat; \
    lhz  %r2, 0(%r5); \
    nop; \
    li  %r2, 2; \
  )

  TEST_PASSFAIL

PPCTEST_CODE_END

  .data
PPCTEST_DATA_BEGIN

  TEST_DATA

tdat:
tdat1:  .short 0x00ff
tdat2:  .short 0xff00
tdat3:  .short 0x0ff0
tdat4:  .short 0xf00f

PPCTEST_DATA_END
