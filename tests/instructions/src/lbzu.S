# See LICENSE for license details.

#*****************************************************************************
# lbzu.S
#-----------------------------------------------------------------------------
#
# Test lbzu instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  TEST_LD_OP( 2, lbzu, 0x00000000000000ff, 0,  tdat );
  TEST_LD_OP( 3, lbzu, 0x0000000000000000, 1,  tdat );
  TEST_LD_OP( 4, lbzu, 0x00000000000000f0, 2,  tdat );
  TEST_LD_OP( 5, lbzu, 0x000000000000000f, 3, tdat );

  # Test with negative offset

  TEST_LD_OP( 6, lbzu, 0x00000000000000ff, -3, tdat4 );
  TEST_LD_OP( 7, lbzu, 0x0000000000000000, -2,  tdat4 );
  TEST_LD_OP( 8, lbzu, 0x00000000000000f0, -1,  tdat4 );
  TEST_LD_OP( 9, lbzu, 0x000000000000000f, 0,   tdat4 );

  # Test with a negative base

  TEST_CASE( 10, %r5, 0x00000000000000ff, \
    li  %r1, tdat; \
    addi %r1, %r1, -32; \
    lbzu %r5, 32(%r1); \
  )

  # Test with unaligned base

  TEST_CASE( 11, %r5, 0x0000000000000000, \
    li  %r1, tdat; \
    addi %r1, %r1, -6; \
    lbzu %r5, 7(%r1); \
  )

  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  TEST_LD_DEST_BYPASS( 12, 0, lbzu, 0x00000000000000f0, 1, tdat2 );
  TEST_LD_DEST_BYPASS( 13, 1, lbzu, 0x000000000000000f, 1, tdat3 );
  TEST_LD_DEST_BYPASS( 14, 2, lbzu, 0x0000000000000000, 1, tdat1 );

  TEST_LD_SRC1_BYPASS( 15, 0, lbzu, 0x00000000000000f0, 1, tdat2 );
  TEST_LD_SRC1_BYPASS( 16, 1, lbzu, 0x000000000000000f, 1, tdat3 );
  TEST_LD_SRC1_BYPASS( 17, 2, lbzu, 0x0000000000000000, 1, tdat1 );

  #-------------------------------------------------------------
  # Test write-after-write hazard
  #-------------------------------------------------------------

  TEST_CASE( 18, %r2, 2, \
    li  %r5, tdat; \
    lbzu  %r2, 0(%r5); \
    li  %r2, 2; \
  )

  TEST_CASE( 19, %r2, 2, \
    li  %r5, tdat; \
    lbzu  %r2, 0(%r5); \
    nop; \
    li  %r2, 2; \
  )

  TEST_PASSFAIL

PPCTEST_CODE_END

  .data
PPCTEST_DATA_BEGIN

  TEST_DATA

tdat:
tdat1:  .byte 0xff
tdat2:  .byte 0x00
tdat3:  .byte 0xf0
tdat4:  .byte 0x0f

PPCTEST_DATA_END
