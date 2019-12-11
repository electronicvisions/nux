# See LICENSE for license details.

#*****************************************************************************
# lwzu.S
#-----------------------------------------------------------------------------
#
# Test lwzu instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  TEST_LD_OP( 2, lwzu, 0x0000000000ff00ff, 0,  tdat );
  TEST_LD_OP( 3, lwzu, 0x00000000ff00ff00, 4,  tdat );
  TEST_LD_OP( 4, lwzu, 0x000000000ff00ff0, 8,  tdat );
  TEST_LD_OP( 5, lwzu, 0x00000000f00ff00f, 12, tdat );

  # Test with negative offset

  TEST_LD_OP( 6, lwzu, 0x0000000000ff00ff, -12, tdat4 );
  TEST_LD_OP( 7, lwzu, 0x00000000ff00ff00, -8,  tdat4 );
  TEST_LD_OP( 8, lwzu, 0x000000000ff00ff0, -4,  tdat4 );
  TEST_LD_OP( 9, lwzu, 0x00000000f00ff00f, 0,   tdat4 );

  # Test with a negative base

  TEST_CASE( 10, %r5, 0x0000000000ff00ff, \
    li  %r1, tdat; \
    addi %r1, %r1, -32; \
    lwzu %r5, 32(%r1); \
  )

  # Test with unaligned base

  TEST_CASE( 11, %r5, 0x00000000ff00ff00, \
    li  %r1, tdat; \
    addi %r1, %r1, -3; \
    lwzu %r5, 7(%r1); \
  )

  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  TEST_LD_DEST_BYPASS( 12, 0, lwzu, 0x000000000ff00ff0, 4, tdat2 );
  TEST_LD_DEST_BYPASS( 13, 1, lwzu, 0x00000000f00ff00f, 4, tdat3 );
  TEST_LD_DEST_BYPASS( 14, 2, lwzu, 0x00000000ff00ff00, 4, tdat1 );

  TEST_LD_SRC1_BYPASS( 15, 0, lwzu, 0x000000000ff00ff0, 4, tdat2 );
  TEST_LD_SRC1_BYPASS( 16, 1, lwzu, 0x00000000f00ff00f, 4, tdat3 );
  TEST_LD_SRC1_BYPASS( 17, 2, lwzu, 0x00000000ff00ff00, 4, tdat1 );

  #-------------------------------------------------------------
  # Test write-after-write hazard
  #-------------------------------------------------------------

  TEST_CASE( 18, %r2, 2, \
    li  %r5, tdat; \
    lwzu %r2, 0(%r5); \
    li  %r2, 2; \
  )

  TEST_CASE( 19, %r2, 2, \
    li  %r5, tdat; \
    lwzu %r2, 0(%r5); \
    nop; \
    li  %r2, 2; \
  )

  TEST_PASSFAIL

PPCTEST_CODE_END

  .data
PPCTEST_DATA_BEGIN

  TEST_DATA

tdat:
tdat1:  .long 0x00ff00ff
tdat2:  .long 0xff00ff00
tdat3:  .long 0x0ff00ff0
tdat4:  .long 0xf00ff00f

PPCTEST_DATA_END
