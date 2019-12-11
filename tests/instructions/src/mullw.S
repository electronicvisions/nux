# See LICENSE for license details.

#*****************************************************************************
# mullw.S
#-----------------------------------------------------------------------------
#
# Test mullw instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Arithmetic tests
#-------------------------------------------------------------

TEST_RR_OP(32,  mullw, 0x00001200, 0x00007e00, 0xb6db6db7 ) ;
TEST_RR_OP(33,  mullw, 0x00001240, 0x00007fc0, 0xb6db6db7 ) ;

TEST_RR_OP( 2,  mullw, 0x00000000, 0x00000000, 0x00000000 ) ;
TEST_RR_OP( 3,  mullw, 0x00000001, 0x00000001, 0x00000001 ) ;
TEST_RR_OP( 4,  mullw, 0x00000015, 0x00000003, 0x00000007 ) ;

TEST_RR_OP( 5,  mullw, 0x00000000, 0x00000000, 0xffff8000 ) ;
TEST_RR_OP( 6,  mullw, 0x00000000, 0x80000000, 0x00000000 ) ;
TEST_RR_OP( 7,  mullw, 0x00000000, 0x80000000, 0xffff8000 ) ;

TEST_RR_OP(30,  mullw, 0x0000ff7f, 0xaaaaaaab, 0x0002fe7d ) ;
TEST_RR_OP(31,  mullw, 0x0000ff7f, 0x0002fe7d, 0xaaaaaaab ) ;

TEST_RR_OP(34,  mullw, 0x00000000, 0xff000000, 0xff000000 ) ;

TEST_RR_OP(35,  mullw, 0x00000001, 0xffffffff, 0xffffffff ) ;
TEST_RR_OP(36,  mullw, 0xffffffff, 0xffffffff, 0x00000001 ) ;
TEST_RR_OP(37,  mullw, 0xffffffff, 0x00000001, 0xffffffff ) ;

#-------------------------------------------------------------
# Source/Destination tests
#-------------------------------------------------------------

TEST_RR_SRC1_EQ_DEST( 8, mullw, 143, 13, 11 ) ;
TEST_RR_SRC2_EQ_DEST( 9, mullw, 154, 14, 11 ) ;
TEST_RR_SRC12_EQ_DEST( 10, mullw, 169, 13 ) ;

#-------------------------------------------------------------
# Bypassing tests
#-------------------------------------------------------------

TEST_RR_DEST_BYPASS( 11, 0, mullw, 143, 13, 11 ) ;
TEST_RR_DEST_BYPASS( 12, 1, mullw, 154, 14, 11 ) ;
TEST_RR_DEST_BYPASS( 13, 2, mullw, 165, 15, 11 ) ;

TEST_RR_SRC12_BYPASS( 14, 0, 0, mullw, 143, 13, 11 ) ;
TEST_RR_SRC12_BYPASS( 15, 0, 1, mullw, 154, 14, 11 ) ;
TEST_RR_SRC12_BYPASS( 16, 0, 2, mullw, 165, 15, 11 ) ;
TEST_RR_SRC12_BYPASS( 17, 1, 0, mullw, 143, 13, 11 ) ;
TEST_RR_SRC12_BYPASS( 18, 1, 1, mullw, 154, 14, 11 ) ;
TEST_RR_SRC12_BYPASS( 19, 2, 0, mullw, 165, 15, 11 ) ;

TEST_RR_SRC21_BYPASS( 20, 0, 0, mullw, 143, 13, 11 ) ;
TEST_RR_SRC21_BYPASS( 21, 0, 1, mullw, 154, 14, 11 ) ;
TEST_RR_SRC21_BYPASS( 22, 0, 2, mullw, 165, 15, 11 ) ;
TEST_RR_SRC21_BYPASS( 23, 1, 0, mullw, 143, 13, 11 ) ;
TEST_RR_SRC21_BYPASS( 24, 1, 1, mullw, 154, 14, 11 ) ;
TEST_RR_SRC21_BYPASS( 25, 2, 0, mullw, 165, 15, 11 ) ;


TEST_PASSFAIL

PPCTEST_CODE_END

.data
PPCTEST_DATA_BEGIN

TEST_DATA

PPCTEST_DATA_END
