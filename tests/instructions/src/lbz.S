# See LICENSE for license details.

#*****************************************************************************
# lbz.S
#-----------------------------------------------------------------------------
#
# Test lbz instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  TEST_LD_OP( 2, lbz, 0xff, 0,  tdat );
  TEST_LD_OP( 3, lbz, 0x00, 1,  tdat );
  TEST_LD_OP( 4, lbz, 0xf0, 2,  tdat );
  TEST_LD_OP( 5, lbz, 0x0f, 3, tdat );

  # Test with negative offset

  TEST_LD_OP( 6, lbz, 0xff, -3, tdat4 );
  TEST_LD_OP( 7, lbz, 0x00, -2,  tdat4 );
  TEST_LD_OP( 8, lbz, 0xf0, -1,  tdat4 );
  TEST_LD_OP( 9, lbz, 0x0f, 0,   tdat4 );

  # Test with a negative base

  TEST_CASE( 10, %r5, 0xff, \
    li  %r1, tdat; \
    addi %r1, %r1, -32; \
    lbz %r5, 32(%r1); \
  )

  # Test with unaligned base

  TEST_CASE( 11, %r5, 0x00, \
    li  %r1, tdat; \
    addi %r1, %r1, -6; \
    lbz %r5, 7(%r1); \
  )

  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  TEST_LD_DEST_BYPASS( 12, 0, lbz, 0xf0, 1, tdat2 );
  TEST_LD_DEST_BYPASS( 13, 1, lbz, 0x0f, 1, tdat3 );
  TEST_LD_DEST_BYPASS( 14, 2, lbz, 0x00, 1, tdat1 );

  TEST_LD_SRC1_BYPASS( 15, 0, lbz, 0xf0, 1, tdat2 );
  TEST_LD_SRC1_BYPASS( 16, 1, lbz, 0x0f, 1, tdat3 );
  TEST_LD_SRC1_BYPASS( 17, 2, lbz, 0x00, 1, tdat1 );

  #-------------------------------------------------------------
  # Test write-after-write hazard
  #-------------------------------------------------------------

  TEST_CASE( 18, %r2, 2, \
    li  %r5, tdat; \
    lbz  %r2, 0(%r5); \
    li  %r2, 2; \
  )

  TEST_CASE( 19, %r2, 2, \
    li  %r5, tdat; \
    lbz  %r2, 0(%r5); \
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
