# See LICENSE for license details.

#*****************************************************************************
# stw.S
#-----------------------------------------------------------------------------
#
# Test sw instruction.
#

#include "ppc_test.h"
#include "test_macros.h"


PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Basic tests
#-------------------------------------------------------------

TEST_ST_OP( 2, lwz, stw, 0x0000000000aa00aa, 0,  tdat ) ;
TEST_ST_OP( 3, lwz, stw, 0xffffffffaa00aa00, 4,  tdat ) ;
TEST_ST_OP( 4, lwz, stw, 0x000000000aa00aa0, 8,  tdat ) ;
TEST_ST_OP( 5, lwz, stw, 0xffffffffa00aa00a, 12, tdat ) ;

# Test with negative offset

TEST_ST_OP( 6, lwz, stw, 0x0000000000aa00aa, -12, tdat8 ) ;
TEST_ST_OP( 7, lwz, stw, 0xffffffffaa00aa00, -8,  tdat8 ) ;
TEST_ST_OP( 8, lwz, stw, 0x000000000aa00aa0, -4,  tdat8 ) ;
TEST_ST_OP( 9, lwz, stw, 0xffffffffa00aa00a, 0,   tdat8 ) ;

# Test with a negative base

TEST_CASE( 10, 5, 0x12345678, \
LOAD_CONSTANT(1, tdat9)	; \
LOAD_CONSTANT(2, 0x12345678)	; \
addi 4, 1, -32	; \
stw 2, 32(4)	; \
lwz 5, 0(1)	; \
)

# Test with unaligned base

TEST_CASE( 11, 5, 0x58213098, \
LOAD_CONSTANT(1, tdat9)	; \
LOAD_CONSTANT(2, 0x58213098)	; \
addi 1, 1, -3	; \
stw 2, 7(1)	; \
LOAD_CONSTANT(4, tdat10) ; \
lwz 5, 0(4)	; \
)

#-------------------------------------------------------------
# Bypassing tests
#-------------------------------------------------------------

TEST_ST_SRC12_BYPASS( 12, 0, 0, lwz, stw, 0xffffffffaabbccdd, 0,  tdat ) ;
TEST_ST_SRC12_BYPASS( 13, 0, 1, lwz, stw, 0xffffffffdaabbccd, 4,  tdat ) ;
TEST_ST_SRC12_BYPASS( 14, 0, 2, lwz, stw, 0xffffffffddaabbcc, 8,  tdat ) ;
TEST_ST_SRC12_BYPASS( 15, 1, 0, lwz, stw, 0xffffffffcddaabbc, 12, tdat ) ;
TEST_ST_SRC12_BYPASS( 16, 1, 1, lwz, stw, 0xffffffffccddaabb, 16, tdat ) ;
TEST_ST_SRC12_BYPASS( 17, 2, 0, lwz, stw, 0xffffffffbccddaab, 20, tdat ) ;

TEST_ST_SRC21_BYPASS( 18, 0, 0, lwz, stw, 0x00112233, 0,  tdat ) ;
TEST_ST_SRC21_BYPASS( 19, 0, 1, lwz, stw, 0x30011223, 4,  tdat ) ;
TEST_ST_SRC21_BYPASS( 20, 0, 2, lwz, stw, 0x33001122, 8,  tdat ) ;
TEST_ST_SRC21_BYPASS( 21, 1, 0, lwz, stw, 0x23300112, 12, tdat ) ;
TEST_ST_SRC21_BYPASS( 22, 1, 1, lwz, stw, 0x22330011, 16, tdat ) ;
TEST_ST_SRC21_BYPASS( 23, 2, 0, lwz, stw, 0x12233001, 20, tdat ) ;

TEST_PASSFAIL

PPCTEST_CODE_END

PPCTEST_DATA_BEGIN

TEST_DATA

tdat:
tdat1:	  .long 0xdeadbeef
tdat2:	  .long 0xdeadbeef
tdat3:	  .long 0xdeadbeef
tdat4:	  .long 0xdeadbeef
tdat5:	  .long 0xdeadbeef
tdat6:	  .long 0xdeadbeef
tdat7:	  .long 0xdeadbeef
tdat8:	  .long 0xdeadbeef
tdat9:	  .long 0xdeadbeef
tdat10:	 .long 0xdeadbeef

PPCTEST_DATA_END
