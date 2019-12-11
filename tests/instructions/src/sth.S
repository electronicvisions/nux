# See LICENSE for license details.

#*****************************************************************************
# sth.S
#-----------------------------------------------------------------------------
#
# Test sth instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  TEST_ST_OP( 2, lhz, sth, 0x00aa, 0, tdat );
  TEST_ST_OP( 3, lhz, sth, 0xaa00, 2, tdat );
  //TEST_ST_OP( 4, lwz, sth, 0xbeef0aa0, 4, tdat );//this test is for little endian
  TEST_ST_OP( 5, lhz, sth, 0xa00a, 6, tdat );

  # Test with negative offset

  TEST_ST_OP( 6, lhz, sth, 0x00aa, -6, tdat8 );
  TEST_ST_OP( 7, lhz, sth, 0xaa00, -4, tdat8 );
  TEST_ST_OP( 8, lhz, sth, 0x0aa0, -2, tdat8 );
  TEST_ST_OP( 9, lhz, sth, 0xa00a, 0,  tdat8 );

  # Test with a negative base

  TEST_CASE( 10, %r5, 0x5678, \
    li  %r1, tdat9; \
    lis  %r2, 0x1234; \
    ori  %r2, %r2, 0x5678; \
    addi %r4, %r1, -32; \
    sth %r2, 32(%r4); \
    lhz %r5, 0(%r1); \
  )

  # Test with unaligned base

  TEST_CASE( 11, %r5, 0x3098, \
    li  %r1, tdat9; \
    li  %r2, 0x00003098; \
    addi %r1, %r1, -5; \
    sth %r2, 7(%r1); \
    li  %r4, tdat10; \
    lhz %r5, 0(%r4); \
  )

  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  TEST_ST_SRC12_BYPASS( 12, 0, 0, lhz, sth, 0xccdd, 0,  tdat );
  TEST_ST_SRC12_BYPASS( 13, 0, 1, lhz, sth, 0xbccd, 2,  tdat );
  TEST_ST_SRC12_BYPASS( 14, 0, 2, lhz, sth, 0xbbcc, 4,  tdat );
  TEST_ST_SRC12_BYPASS( 15, 1, 0, lhz, sth, 0xabbc, 6, tdat );
  TEST_ST_SRC12_BYPASS( 16, 1, 1, lhz, sth, 0xaabb, 8, tdat );
  TEST_ST_SRC12_BYPASS( 17, 2, 0, lhz, sth, 0xdaab, 10, tdat );

  TEST_ST_SRC21_BYPASS( 18, 0, 0, lhz, sth, 0x2233, 0,  tdat );
  TEST_ST_SRC21_BYPASS( 19, 0, 1, lhz, sth, 0x1223, 2,  tdat );
  TEST_ST_SRC21_BYPASS( 20, 0, 2, lhz, sth, 0x1122, 4,  tdat );
  TEST_ST_SRC21_BYPASS( 21, 1, 0, lhz, sth, 0x0112, 6, tdat );
  TEST_ST_SRC21_BYPASS( 22, 1, 1, lhz, sth, 0x0011, 8, tdat );
  TEST_ST_SRC21_BYPASS( 23, 2, 0, lhz, sth, 0x3001, 10, tdat );

  lis  %r10, MASK_XLEN_HI(0xbeef) | MASK_SIGN_HI(0xbeef); \
  ori  %r10, %r10, MASK_XLEN_LO(0xbeef) | MASK_SIGN_LO(0xbeef); \
  li %r11, tdat
  sth %r10, 6(%r11)

  TEST_PASSFAIL

PPCTEST_CODE_END

  .data
PPCTEST_DATA_BEGIN

  TEST_DATA

tdat:
tdat1:  .short 0xbeef
tdat2:  .short 0xbeef
tdat3:  .short 0xbeef
tdat4:  .short 0xbeef
tdat5:  .short 0xbeef
tdat6:  .short 0xbeef
tdat7:  .short 0xbeef
tdat8:  .short 0xbeef
tdat9:  .short 0xbeef
tdat10: .short 0xbeef

PPCTEST_DATA_END
