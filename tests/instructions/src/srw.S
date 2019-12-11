# See LICENSE for license details.

#*****************************************************************************
# srw.S
#-----------------------------------------------------------------------------
#
# Test srw instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Arithmetic tests
#-------------------------------------------------------------

#define TEST_SRW(n, v, a) \
TEST_RR_OP(n, srw, ((v) & ((1 << (32-1) << 1) - 1)) >> (a), v, a)

TEST_SRW( 2,  0xffffffff80000000, 0  ) ;
TEST_SRW( 3,  0xffffffff80000000, 1  ) ;
TEST_SRW( 4,  0xffffffff80000000, 7  ) ;
TEST_SRW( 5,  0xffffffff80000000, 14 ) ;
TEST_SRW( 6,  0xffffffff80000001, 31 ) ;

TEST_SRW( 7,  0xffffffffffffffff, 0  ) ;
TEST_SRW( 8,  0xffffffffffffffff, 1  ) ;
TEST_SRW( 9,  0xffffffffffffffff, 7  ) ;
TEST_SRW( 10, 0xffffffffffffffff, 14 ) ;
TEST_SRW( 11, 0xffffffffffffffff, 31 ) ;

TEST_SRW( 12, 0x0000000021212121, 0  ) ;
TEST_SRW( 13, 0x0000000021212121, 1  ) ;
TEST_SRW( 14, 0x0000000021212121, 7  ) ;
TEST_SRW( 15, 0x0000000021212121, 14 ) ;
TEST_SRW( 16, 0x0000000021212121, 31 ) ;

# Verify that shifts only use bottom five bits

TEST_RR_OP( 17, srw, 0x0000000021212121, 0x0000000021212121, 0xffffffffffffffc0 ) ;
TEST_RR_OP( 18, srw, 0x0000000010909090, 0x0000000021212121, 0xffffffffffffffc1 ) ;
TEST_RR_OP( 19, srw, 0x0000000000424242, 0x0000000021212121, 0xffffffffffffffc7 ) ;
TEST_RR_OP( 20, srw, 0x0000000000008484, 0x0000000021212121, 0xffffffffffffffce ) ;
TEST_RR_OP( 21, srw, 0x0000000000000000, 0x0000000021212121, 0xffffffffffffffff ) ;

#-------------------------------------------------------------
# Source/Destination tests
#-------------------------------------------------------------

TEST_RR_SRC1_EQ_DEST( 22, srw, 0x01000000, 0x80000000, 7  ) ;
TEST_RR_SRC2_EQ_DEST( 23, srw, 0x00020000, 0x80000000, 14 ) ;
TEST_RR_SRC12_EQ_DEST( 24, srw, 0, 7 )		    ;

#-------------------------------------------------------------
# Bypassing tests
#-------------------------------------------------------------

TEST_RR_DEST_BYPASS( 25, 0, srw, 0x01000000, 0x80000000, 7  ) ;
TEST_RR_DEST_BYPASS( 26, 1, srw, 0x00020000, 0x80000000, 14 ) ;
TEST_RR_DEST_BYPASS( 27, 2, srw, 0x00000001, 0x80000000, 31 ) ;

TEST_RR_SRC12_BYPASS( 28, 0, 0, srw, 0x01000000, 0x80000000, 7  ) ;
TEST_RR_SRC12_BYPASS( 29, 0, 1, srw, 0x00020000, 0x80000000, 14 ) ;
TEST_RR_SRC12_BYPASS( 30, 0, 2, srw, 0x00000001, 0x80000000, 31 ) ;
TEST_RR_SRC12_BYPASS( 31, 1, 0, srw, 0x01000000, 0x80000000, 7  ) ;
TEST_RR_SRC12_BYPASS( 32, 1, 1, srw, 0x00020000, 0x80000000, 14 ) ;
TEST_RR_SRC12_BYPASS( 33, 2, 0, srw, 0x00000001, 0x80000000, 31 ) ;

TEST_RR_SRC21_BYPASS( 34, 0, 0, srw, 0x01000000, 0x80000000, 7  ) ;
TEST_RR_SRC21_BYPASS( 35, 0, 1, srw, 0x00020000, 0x80000000, 14 ) ;
TEST_RR_SRC21_BYPASS( 36, 0, 2, srw, 0x00000001, 0x80000000, 31 ) ;
TEST_RR_SRC21_BYPASS( 37, 1, 0, srw, 0x01000000, 0x80000000, 7  ) ;
TEST_RR_SRC21_BYPASS( 38, 1, 1, srw, 0x00020000, 0x80000000, 14 ) ;
TEST_RR_SRC21_BYPASS( 39, 2, 0, srw, 0x00000001, 0x80000000, 31 ) ;

TEST_RR_ZEROSRC1( 40, srw, 0, 15 ) ;
TEST_RR_ZEROSRC2( 41, srw, 32, 32 ) ;
TEST_RR_ZEROSRC12( 42, srw, 0 )   ;

TEST_PASSFAIL

PPCTEST_CODE_END

.data
PPCTEST_DATA_BEGIN

TEST_DATA

PPCTEST_DATA_END
