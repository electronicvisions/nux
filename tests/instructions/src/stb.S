# See LICENSE for license details.

#*****************************************************************************
# stb.S
#-----------------------------------------------------------------------------
#
# Test stb instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  TEST_ST_OP( 2, lbz, stb, 0xaa, 0, tdat );
  TEST_ST_OP( 3, lbz, stb, 0x00, 1, tdat );
  //TEST_ST_OP( 4, lhz, stb, 0xefa0, 2, tdat );//this test is for little endian
  TEST_ST_OP( 5, lbz, stb, 0x0a, 3, tdat );

  # Test with negative offset

  TEST_ST_OP( 6, lbz, stb, 0xaa, -3, tdat8 );
  TEST_ST_OP( 7, lbz, stb, 0x00, -2, tdat8 );
  TEST_ST_OP( 8, lbz, stb, 0xa0, -1, tdat8 );
  TEST_ST_OP( 9, lbz, stb, 0x0a, 0,  tdat8 );

  # Test with a negative base

  TEST_CASE( 10, %r5, 0x78, \
    li  %r1, tdat9; \
    lis  %r2, 0x1234; \
    ori  %r2, %r2, 0x5678; \
    addi %r4, %r1, -32; \
    stb %r2, 32(%r4); \
    lbz %r5, 0(%r1); \
  )

  # Test with unaligned base

  TEST_CASE( 11, %r5, 0x98, \
    li  %r1, tdat9; \
    li  %r2, 0x00003098; \
    addi %r1, %r1, -6; \
    stb %r2, 7(%r1); \
    li  %r4, tdat10; \
    lbz %r5, 0(%r4); \
  )

  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  TEST_ST_SRC12_BYPASS( 12, 0, 0, lbz, stb, 0xdd, 0, tdat );
  TEST_ST_SRC12_BYPASS( 13, 0, 1, lbz, stb, 0xcd, 1, tdat );
  TEST_ST_SRC12_BYPASS( 14, 0, 2, lbz, stb, 0xcc, 2, tdat );
  TEST_ST_SRC12_BYPASS( 15, 1, 0, lbz, stb, 0xbc, 3, tdat );
  TEST_ST_SRC12_BYPASS( 16, 1, 1, lbz, stb, 0xbb, 4, tdat );
  TEST_ST_SRC12_BYPASS( 17, 2, 0, lbz, stb, 0xab, 5, tdat );

  TEST_ST_SRC21_BYPASS( 18, 0, 0, lbz, stb, 0x33, 0, tdat );
  TEST_ST_SRC21_BYPASS( 19, 0, 1, lbz, stb, 0x23, 1, tdat );
  TEST_ST_SRC21_BYPASS( 20, 0, 2, lbz, stb, 0x22, 2, tdat );
  TEST_ST_SRC21_BYPASS( 21, 1, 0, lbz, stb, 0x12, 3, tdat );
  TEST_ST_SRC21_BYPASS( 22, 1, 1, lbz, stb, 0x11, 4, tdat );
  TEST_ST_SRC21_BYPASS( 23, 2, 0, lbz, stb, 0x01, 5, tdat );

  li %r10, 0xef
  li %r11, tdat
  stb %r10, 3(%r11)

  TEST_PASSFAIL

PPCTEST_CODE_END

  .data
PPCTEST_DATA_BEGIN

  TEST_DATA

tdat:
tdat1:  .byte 0xef
tdat2:  .byte 0xef
tdat3:  .byte 0xef
tdat4:  .byte 0xef
tdat5:  .byte 0xef
tdat6:  .byte 0xef
tdat7:  .byte 0xef
tdat8:  .byte 0xef
tdat9:  .byte 0xef
tdat10: .byte 0xef

PPCTEST_DATA_END
