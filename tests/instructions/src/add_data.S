# See LICENSE for license details.

#*****************************************************************************
# add.S
#-----------------------------------------------------------------------------
#
# Test add instruction.
#

#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Arithmetic tests
  #-------------------------------------------------------------

  TEST_RR_DAT( 2,  add, dat0, dat0, dat0 );
  TEST_RR_DAT( 3,  add, dat2, dat1, dat1 );
  TEST_RR_DAT( 4,  add, dat3, dat4, dat5 );

  TEST_RR_DAT( 5,  add, dat6, dat0, dat6 );
  TEST_RR_DAT( 6,  add, dat7, dat7, dat0 );
  TEST_RR_DAT( 7,  add, dat8, dat7, dat6 );

  TEST_RR_DAT( 8,  add, dat9, dat0, dat9 );
  TEST_RR_DAT( 9,  add, dat10, dat10, dat0 );
  TEST_RR_DAT( 10, add, dat16, dat10, dat9 );

  TEST_RR_DAT( 11, add, dat15, dat7, dat9 );
  TEST_RR_DAT( 12, add, dat12, dat10, dat6 );

  TEST_RR_DAT( 13, add, dat10, dat0, dat10 );
  TEST_RR_DAT( 14, add, dat7, dat10, dat1 );
  TEST_RR_DAT( 15, add, dat14, dat10, dat10 );

  TEST_RR_DAT( 16, add, dat7, dat1, dat10 );

  TEST_PASSFAIL

PPCTEST_CODE_END

.data
  dat0:  .long 0x00000000
  dat1:  .long 0x00000001
  dat2:  .long 0x00000002
  dat3:  .long 0x0000000a
  dat4:  .long 0x00000003
  dat5:  .long 0x00000007
  dat6:  .long 0xffff8000
  dat7:  .long 0x80000000
  dat8:  .long 0x7fff8000
  dat9:  .long 0x00007fff
  dat10: .long 0x7fffffff
  dat11: .long 0x00007ffe
  dat12: .long 0x7fff7fff
  dat13: .long 0xffffffff
  dat14: .long 0xfffffffe
  dat15: .long 0x80007fff
  dat16: .long 0x80007ffe


  TEST_DATA

