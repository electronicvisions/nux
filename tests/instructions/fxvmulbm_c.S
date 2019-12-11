#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Basic tests
#-------------------------------------------------------------

# Signature of TEST_FXV_C_RR_OP is:
# testnum, inst, size, expected, val1, val2, mask, default, cond, result

# Zero
TEST_FXV_C_RR_OP(2, fxvmulbm, b, exp2, 0, 1, mask, 0xaa, 0, res)
TEST_FXV_C_RR_OP(3, fxvmulbm, b, exp3, 0, 1, mask, 0xaa, 1, res)
TEST_FXV_C_RR_OP(4, fxvmulbm, b, exp4, 0, 1, mask, 0xaa, 2, res)
TEST_FXV_C_RR_OP(5, fxvmulbm, b, exp5, 0, 1, mask, 0xaa, 3, res)

# Typical
TEST_FXV_C_RR_OP(6, fxvmulbm, b, exp6, 2, 3, mask, 0xaa, 0, res)
TEST_FXV_C_RR_OP(7, fxvmulbm, b, exp7, 2, 3, mask, 0xaa, 1, res)
TEST_FXV_C_RR_OP(8, fxvmulbm, b, exp8, 2, 3, mask, 0xaa, 2, res)
TEST_FXV_C_RR_OP(9, fxvmulbm, b, exp9, 2, 3, mask, 0xaa, 3, res)

# Overflow
TEST_FXV_C_RR_OP(10, fxvmulbm, b, exp10, 0x81, 2, mask, 0xaa, 0, res)
TEST_FXV_C_RR_OP(11, fxvmulbm, b, exp11, 0x81, 2, mask, 0xaa, 1, res)
TEST_FXV_C_RR_OP(12, fxvmulbm, b, exp12, 0x81, 2, mask, 0xaa, 2, res)
TEST_FXV_C_RR_OP(13, fxvmulbm, b, exp13, 0x81, 2, mask, 0xaa, 3, res)


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
exp6:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x06060606 # condition always
exp7:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaa06aa # condition gt
exp8:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaaaa06 # condition lt
exp9:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0606aaaa # condition eq
exp10:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x02020202 # condition always
exp11:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaa02aa # condition gt
exp12:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaaaa02 # condition lt
exp13:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0202aaaa # condition eq

res:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE * 14, 1, 0xff

PPCTEST_DATA_END
