#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Basic tests
#-------------------------------------------------------------

# Signature of TEST_FXV_C_RR_OP is:
# testnum, inst, size, expected, val1, val2, mask, default, cond, result

# Zero
TEST_FXV_C_RR_OP(2, fxvmulhm, h, exp2, 0, 1, mask, 0xaaaa, 0, res)
TEST_FXV_C_RR_OP(3, fxvmulhm, h, exp3, 0, 1, mask, 0xaaaa, 1, res)
TEST_FXV_C_RR_OP(4, fxvmulhm, h, exp4, 0, 1, mask, 0xaaaa, 2, res)
TEST_FXV_C_RR_OP(5, fxvmulhm, h, exp5, 0, 1, mask, 0xaaaa, 3, res)

# Typical
TEST_FXV_C_RR_OP(6, fxvmulhm, h, exp6, 2, 3, mask, 0xaaaa, 0, res)
TEST_FXV_C_RR_OP(7, fxvmulhm, h, exp7, 2, 3, mask, 0xaaaa, 1, res)
TEST_FXV_C_RR_OP(8, fxvmulhm, h, exp8, 2, 3, mask, 0xaaaa, 2, res)
TEST_FXV_C_RR_OP(9, fxvmulhm, h, exp9, 2, 3, mask, 0xaaaa, 3, res)

# Overflow
TEST_FXV_C_RR_OP(10, fxvmulhm, h, exp10, 0x8001, 2, mask, 0xaaaa, 0, res)
TEST_FXV_C_RR_OP(11, fxvmulhm, h, exp11, 0x8001, 2, mask, 0xaaaa, 1, res)
TEST_FXV_C_RR_OP(12, fxvmulhm, h, exp12, 0x8001, 2, mask, 0xaaaa, 2, res)
TEST_FXV_C_RR_OP(13, fxvmulhm, h, exp13, 0x8001, 2, mask, 0xaaaa, 3, res)


TEST_PASSFAIL

PPCTEST_CODE_END

PPCTEST_DATA_BEGIN

TEST_DATA

.align 4
mask:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0001ffff
exp2:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x00000000 # condition always
exp3:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0000aaaa # condition gt
exp4:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaa0000 # condition lt
exp5:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaaaaaa # condition eq
exp6:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x00060006 # condition always
exp7:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0006aaaa # condition gt
exp8:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaa0006 # condition lt
exp9:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaaaaaa # condition eq
exp10:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x00020002 # condition always
exp11:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0002aaaa # condition gt
exp12:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaa0002 # condition lt
exp13:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaaaaaa # condition eq

res:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE * 14, 1, 0xff

PPCTEST_DATA_END
