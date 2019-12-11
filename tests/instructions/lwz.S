# See LICENSE for license details.

#*****************************************************************************
# lwz.S
#-----------------------------------------------------------------------------
#
# Test lwz instruction.
#

#include "ppc_test.h"
#include "test_macros.h"


PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Basic tests
#-------------------------------------------------------------

TEST_LD_OP( 2, lwz, 0x0000000000ff00ff, 0,  tdat ) ;
TEST_LD_OP( 3, lwz, 0xffffffffff00ff00, 4,  tdat ) ;
TEST_LD_OP( 4, lwz, 0x000000000ff00ff0, 8,  tdat ) ;
TEST_LD_OP( 5, lwz, 0xfffffffff00ff00f, 12, tdat ) ;

# Test with negative offset

TEST_LD_OP( 6, lwz, 0x0000000000ff00ff, -12, tdat4 ) ;
TEST_LD_OP( 7, lwz, 0xffffffffff00ff00, -8,  tdat4 ) ;
TEST_LD_OP( 8, lwz, 0x000000000ff00ff0, -4,  tdat4 ) ;
TEST_LD_OP( 9, lwz, 0xfffffffff00ff00f, 0,   tdat4 ) ;

# Test with a negative base

TEST_CASE( 10, 5, 0x0000000000ff00ff, \
LOAD_CONSTANT(1, tdat)	; \
addi 1, 1, -32	; \
lwz 5, 32(1)	; \
)

# Test with unaligned base

TEST_CASE( 11, 5, 0xffffffffff00ff00, \
LOAD_CONSTANT(1, tdat)	; \
addi 1, 1, -3	; \
lwz 5, 7(1)	; \
)

#-------------------------------------------------------------
# Bypassing tests
#-------------------------------------------------------------

TEST_LD_DEST_BYPASS( 12, 0, lwz, 0x000000000ff00ff0, 4, tdat2 ) ;
TEST_LD_DEST_BYPASS( 13, 1, lwz, 0xfffffffff00ff00f, 4, tdat3 ) ;
TEST_LD_DEST_BYPASS( 14, 2, lwz, 0xffffffffff00ff00, 4, tdat1 ) ;

TEST_LD_SRC1_BYPASS( 15, 0, lwz, 0x000000000ff00ff0, 4, tdat2 ) ;
TEST_LD_SRC1_BYPASS( 16, 1, lwz, 0xfffffffff00ff00f, 4, tdat3 ) ;
TEST_LD_SRC1_BYPASS( 17, 2, lwz, 0xffffffffff00ff00, 4, tdat1 ) ;

#-------------------------------------------------------------
# Test write-after-write hazard
#-------------------------------------------------------------

TEST_CASE( 18, 2, 2, \
LOAD_CONSTANT(5, tdat)	; \
lwz  2, 0(5)	; \
li  2, 2	; \
)

TEST_CASE( 19, 2, 2, \
LOAD_CONSTANT(5, tdat) ; \
lwz  2, 0(5)	; \
nop		; \
li  2, 2	; \
)

TEST_PASSFAIL

PPCTEST_CODE_END

PPCTEST_DATA_BEGIN

TEST_DATA

tdat:
tdat1:	  .long 0x00ff00ff
tdat2:	  .long 0xff00ff00
tdat3:	  .long 0x0ff00ff0
tdat4:	  .long 0xf00ff00f

PPCTEST_DATA_END
