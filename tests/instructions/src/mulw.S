# See LICENSE for license details.

#*****************************************************************************
# mulhw.S
#-----------------------------------------------------------------------------
#
# Test mulhw instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Arithmetic tests
#-------------------------------------------------------------

TEST_RR_OP( 2,  mulhw, 0x00000000, 0x00000000, 0x00000000 ) ;
TEST_RR_OP( 3,  mulhw, 0x00000000, 0x00000001, 0x00000001 ) ;
TEST_RR_OP( 4,  mulhw, 0x00000000, 0x00000003, 0x00000007 ) ;

TEST_RR_OP( 5,  mulhw, 0x00000000, 0x00000000, 0xffff8000 ) ;
TEST_RR_OP( 6,  mulhw, 0x00000000, 0x80000000, 0x00000000 ) ;
TEST_RR_OP( 7,  mulhw, 0x00000000, 0x80000000, 0x00000000 ) ;

TEST_RR_OP(30,  mulhw, 0xffff0081, 0xaaaaaaab, 0x0002fe7d ) ;
TEST_RR_OP(31,  mulhw, 0xffff0081, 0x0002fe7d, 0xaaaaaaab ) ;

TEST_RR_OP(32,  mulhw, 0x00010000, 0xff000000, 0xff000000 ) ;

TEST_RR_OP(33,  mulhw, 0x00000000, 0xffffffff, 0xffffffff ) ;
TEST_RR_OP(34,  mulhw, 0xffffffff, 0xffffffff, 0x00000001 ) ;
TEST_RR_OP(35,  mulhw, 0xffffffff, 0x00000001, 0xffffffff ) ;

#-------------------------------------------------------------
# Source/Destination tests
#-------------------------------------------------------------

TEST_RR_SRC1_EQ_DEST( 8, mulhw, 36608, 13<<20, 11<<20 ) ;
TEST_RR_SRC2_EQ_DEST( 9, mulhw, 39424, 14<<20, 11<<20 ) ;
TEST_RR_SRC12_EQ_DEST( 10, mulhw, 43264, 13<<20 )	;

#-------------------------------------------------------------
# Bypassing tests
#-------------------------------------------------------------

TEST_RR_DEST_BYPASS( 11, 0, mulhw, 36608, 13<<20, 11<<20 ) ;
TEST_RR_DEST_BYPASS( 12, 1, mulhw, 39424, 14<<20, 11<<20 ) ;
TEST_RR_DEST_BYPASS( 13, 2, mulhw, 42240, 15<<20, 11<<20 ) ;

TEST_RR_SRC12_BYPASS( 14, 0, 0, mulhw, 36608, 13<<20, 11<<20 ) ;
TEST_RR_SRC12_BYPASS( 15, 0, 1, mulhw, 39424, 14<<20, 11<<20 ) ;
TEST_RR_SRC12_BYPASS( 16, 0, 2, mulhw, 42240, 15<<20, 11<<20 ) ;
TEST_RR_SRC12_BYPASS( 17, 1, 0, mulhw, 36608, 13<<20, 11<<20 ) ;
TEST_RR_SRC12_BYPASS( 18, 1, 1, mulhw, 39424, 14<<20, 11<<20 ) ;
TEST_RR_SRC12_BYPASS( 19, 2, 0, mulhw, 42240, 15<<20, 11<<20 ) ;

TEST_RR_SRC21_BYPASS( 20, 0, 0, mulhw, 36608, 13<<20, 11<<20 ) ;
TEST_RR_SRC21_BYPASS( 21, 0, 1, mulhw, 39424, 14<<20, 11<<20 ) ;
TEST_RR_SRC21_BYPASS( 22, 0, 2, mulhw, 42240, 15<<20, 11<<20 ) ;
TEST_RR_SRC21_BYPASS( 23, 1, 0, mulhw, 36608, 13<<20, 11<<20 ) ;
TEST_RR_SRC21_BYPASS( 24, 1, 1, mulhw, 39424, 14<<20, 11<<20 ) ;
TEST_RR_SRC21_BYPASS( 25, 2, 0, mulhw, 42240, 15<<20, 11<<20 ) ;

TEST_RR_ZEROSRC1( 26, mulhw, 0, 31<<26 ) ;
TEST_RR_ZEROSRC2( 27, mulhw, 0, 32<<26 ) ;
TEST_RR_ZEROSRC12( 28, mulhw, 0 )	 ;

TEST_PASSFAIL

PPCTEST_CODE_END

.data
PPCTEST_DATA_BEGIN

TEST_DATA

PPCTEST_DATA_END
