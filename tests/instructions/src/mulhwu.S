# See LICENSE for license details.

#*****************************************************************************
# mulhwu.S
#-----------------------------------------------------------------------------
#
# Test mulhwu instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Arithmetic tests
  #-------------------------------------------------------------

  TEST_RR_OP( 2,  mulhwu, 0x00000000, 0x00000000, 0x00000000 );
  TEST_RR_OP( 3,  mulhwu, 0x00000000, 0x00000001, 0x00000001 );
  TEST_RR_OP( 4,  mulhwu, 0x00000000, 0x00000003, 0x00000007 );

  TEST_RR_OP( 5,  mulhwu, 0x00000000, 0x00000000, 0xffff8000 );
  TEST_RR_OP( 6,  mulhwu, 0x00000000, 0x80000000, 0x00000000 );
  TEST_RR_OP( 7,  mulhwu, 0x7fffc000, 0x80000000, 0xffff8000 );

  TEST_RR_OP(30,  mulhwu, 0x0001fefe, 0xaaaaaaab, 0x0002fe7d );
  TEST_RR_OP(31,  mulhwu, 0x0001fefe, 0x0002fe7d, 0xaaaaaaab );

  TEST_RR_OP(32,  mulhwu, 0xfe010000, 0xff000000, 0xff000000 );

  TEST_RR_OP(33,  mulhwu, 0xfffffffe, 0xffffffff, 0xffffffff );
  TEST_RR_OP(34,  mulhwu, 0x00000000, 0xffffffff, 0x00000001 );
  TEST_RR_OP(35,  mulhwu, 0x00000000, 0x00000001, 0xffffffff );

  #-------------------------------------------------------------
  # Source/Destination tests
  #-------------------------------------------------------------

  TEST_RR_SRC1_EQ_DEST( 8, mulhwu, 36608, 13<<20, 11<<20 );
  TEST_RR_SRC2_EQ_DEST( 9, mulhwu, 39424, 14<<20, 11<<20 );
  TEST_RR_SRC12_EQ_DEST( 10, mulhwu, 43264, 13<<20 );

  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  TEST_RR_DEST_BYPASS( 11, 0, mulhwu, 36608, 13<<20, 11<<20 );
  TEST_RR_DEST_BYPASS( 12, 1, mulhwu, 39424, 14<<20, 11<<20 );
  TEST_RR_DEST_BYPASS( 13, 2, mulhwu, 42240, 15<<20, 11<<20 );

  TEST_RR_SRC12_BYPASS( 14, 0, 0, mulhwu, 36608, 13<<20, 11<<20 );
  TEST_RR_SRC12_BYPASS( 15, 0, 1, mulhwu, 39424, 14<<20, 11<<20 );
  TEST_RR_SRC12_BYPASS( 16, 0, 2, mulhwu, 42240, 15<<20, 11<<20 );
  TEST_RR_SRC12_BYPASS( 17, 1, 0, mulhwu, 36608, 13<<20, 11<<20 );
  TEST_RR_SRC12_BYPASS( 18, 1, 1, mulhwu, 39424, 14<<20, 11<<20 );
  TEST_RR_SRC12_BYPASS( 19, 2, 0, mulhwu, 42240, 15<<20, 11<<20 );

  TEST_RR_SRC21_BYPASS( 20, 0, 0, mulhwu, 36608, 13<<20, 11<<20 );
  TEST_RR_SRC21_BYPASS( 21, 0, 1, mulhwu, 39424, 14<<20, 11<<20 );
  TEST_RR_SRC21_BYPASS( 22, 0, 2, mulhwu, 42240, 15<<20, 11<<20 );
  TEST_RR_SRC21_BYPASS( 23, 1, 0, mulhwu, 36608, 13<<20, 11<<20 );
  TEST_RR_SRC21_BYPASS( 24, 1, 1, mulhwu, 39424, 14<<20, 11<<20 );
  TEST_RR_SRC21_BYPASS( 25, 2, 0, mulhwu, 42240, 15<<20, 11<<20 );

  TEST_RR_ZEROSRC1( 26, mulhwu, 0, 31<<26 );
  TEST_RR_ZEROSRC2( 27, mulhwu, 0, 32<<26 );
  TEST_RR_ZEROSRC12( 28, mulhwu, 0 );
  //TEST_RR_ZERODEST( 29, mulhwu, 33<<20, 34<<20 );


  TEST_PASSFAIL

PPCTEST_CODE_END

  .data
PPCTEST_DATA_BEGIN

  TEST_DATA

PPCTEST_DATA_END
