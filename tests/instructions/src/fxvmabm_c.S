#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Basic tests
#-------------------------------------------------------------

# Signature of TEST_FXV_C_ACC_RR_OP is:
# testnum, inst, size, expected, val1, val2, mask, default, acc, cond, result

# Zero
TEST_FXV_C_ACC_RR_OP(2, fxvmabm, b, exp2, 0, 0, mask, 0xaa, 0, 0, res)
TEST_FXV_C_ACC_RR_OP(3, fxvmabm, b, exp3, 0, 0, mask, 0xaa, 0, 1, res)
TEST_FXV_C_ACC_RR_OP(4, fxvmabm, b, exp4, 0, 0, mask, 0xaa, 0, 2, res)
TEST_FXV_C_ACC_RR_OP(5, fxvmabm, b, exp5, 0, 0, mask, 0xaa, 0, 3, res)

# Typical
TEST_FXV_C_ACC_RR_OP(6, fxvmabm, b, exp6, 2, 3, mask, 0xaa, 1, 0, res)
TEST_FXV_C_ACC_RR_OP(7, fxvmabm, b, exp7, 2, 3, mask, 0xaa, 1, 1, res)
TEST_FXV_C_ACC_RR_OP(8, fxvmabm, b, exp8, 2, 3, mask, 0xaa, 1, 2, res)
TEST_FXV_C_ACC_RR_OP(9, fxvmabm, b, exp9, 2, 3, mask, 0xaa, 1, 3, res)

# Wrap around
TEST_FXV_C_ACC_RR_OP(10, fxvmabm, b, exp10, 0x81, 2, mask, 0xaa, 1, 0, res)
TEST_FXV_C_ACC_RR_OP(11, fxvmabm, b, exp11, 0x81, 2, mask, 0xaa, 1, 1, res)
TEST_FXV_C_ACC_RR_OP(12, fxvmabm, b, exp12, 0x81, 2, mask, 0xaa, 1, 2, res)
TEST_FXV_C_ACC_RR_OP(13, fxvmabm, b, exp13, 0x81, 2, mask, 0xaa, 1, 3, res)


TEST_PASSFAIL

PPCTEST_CODE_END

PPCTEST_DATA_BEGIN

TEST_DATA

.align 4
mask:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x000001ff
exp2:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x00000000 # condition always
exp3:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaa00aa # condition gt
exp4:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaaaa00 # condition lt
exp5:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0000aaaa # condition eq
exp6:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x07070707 # condition always
exp7:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaa07aa # condition gt
exp8:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaaaa07 # condition lt
exp9:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0707aaaa # condition eq
exp10:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x03030303 # condition always
exp11:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaa03aa # condition gt
exp12:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaaaa03 # condition lt
exp13:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0303aaaa # condition eq

res:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE * 14, 1, 0xff

PPCTEST_DATA_END
