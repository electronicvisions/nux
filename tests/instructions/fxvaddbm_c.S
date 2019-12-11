#include "ppc_test.h"
#include "test_macros.h"

PPCTEST_CODE_BEGIN

#-------------------------------------------------------------
# Basic tests
#-------------------------------------------------------------

# Signature of TEST_FXV_C_RR_OP is:
# testnum, inst, size, expected, val1, val2, mask, default, cond, result

# Zero
TEST_FXV_C_RR_OP(2, fxvaddbm, b, exp2, 0, 0, mask, 0xaa, 0, res)
TEST_FXV_C_RR_OP(3, fxvaddbm, b, exp3, 0, 0, mask, 0xaa, 1, res)
TEST_FXV_C_RR_OP(4, fxvaddbm, b, exp4, 0, 0, mask, 0xaa, 2, res)
TEST_FXV_C_RR_OP(5, fxvaddbm, b, exp5, 0, 0, mask, 0xaa, 3, res)

# Typical
TEST_FXV_C_RR_OP(6, fxvaddbm, b, exp6, 2, 3, mask, 0xaa, 0, res)
TEST_FXV_C_RR_OP(7, fxvaddbm, b, exp7, 2, 3, mask, 0xaa, 1, res)
TEST_FXV_C_RR_OP(8, fxvaddbm, b, exp8, 2, 3, mask, 0xaa, 2, res)
TEST_FXV_C_RR_OP(9, fxvaddbm, b, exp9, 2, 3, mask, 0xaa, 3, res)

# Wrap around
TEST_FXV_C_RR_OP(10, fxvaddbm, b, exp10, 0xff, 2, mask, 0xaa, 0, res)
TEST_FXV_C_RR_OP(11, fxvaddbm, b, exp11, 0xff, 2, mask, 0xaa, 1, res)
TEST_FXV_C_RR_OP(12, fxvaddbm, b, exp12, 0xff, 2, mask, 0xaa, 2, res)
TEST_FXV_C_RR_OP(13, fxvaddbm, b, exp13, 0xff, 2, mask, 0xaa, 3, res)


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
exp6:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x05050505 # condition always
exp7:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaa05aa # condition gt
exp8:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaaaa05 # condition lt
exp9:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0505aaaa # condition eq
exp10:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x01010101 # condition always
exp11:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaa01aa # condition gt
exp12:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0xaaaaaa01 # condition lt
exp13:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4, 4, 0x0101aaaa # condition eq

res:	.fill FXV_NUM_SLICES * FXV_BYTES_PER_SLICE * 14, 1, 0xff

PPCTEST_DATA_END
