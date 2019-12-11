#define PPCTEST_CODE_BEGIN \
.section .text; \
.globl _start; \
_start: \
 li TESTNUM, 0; \

#define PPCTEST_CODE_END

#define PPCTEST_DATA_BEGIN
#define PPCTEST_DATA_END
#define TEST_DATA

#define FXV_NUM_SLICES 8
#define FXV_BYTES_PER_SLICE 16

#define PPCTEST_FAIL \
hang: \
  li 1, 1; \
  cmpw 0, 1; \
  bne hang; \

#define PPCTEST_PASS \
  nop;		     \
  nop;		     \
  nop;               \
  nop;               \
  nop;               \
  nop;		     \
  nop;		     \
  nop;               \
  nop;               \
  nop;               \
  nop;               \
  wait;
