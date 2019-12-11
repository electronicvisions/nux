// See LICENSE for license details.

#ifndef __TEST_MACROS_SCALAR_H
#define __TEST_MACROS_SCALAR_H

#-----------------------------------------------------------------------
# Helper macros
#-----------------------------------------------------------------------

#define immwidth 16
#an immediate operand may only have 16 bits
#immwidth-1 because of sign bit
#establish sign bits, so compiler will not throw an error because of sign bit
#define MASK_XLEN_LO(x) ((x) & ((1 << (immwidth-1)) - 1))
#define MASK_XLEN_HI(x) ((x >> (32 - (immwidth))) & ((1 << (immwidth-1)) - 1))
#define MASK_SIGN_LO(x) ((x) & (1 << (immwidth-1)))
#define MASK_SIGN_HI(x) ((x >> (32 - (immwidth))) & (1 << (immwidth-1)))

#define MASK_XLEN(x) ((x) & ((1 << (32 - 1) << 1) - 1))
#define TESTNUM 31

#define LOAD_CONSTANT(target, value) \
  lis target,value@h;\
  ori target,target,value@l; \

#define TEST_CASE(testnum, testreg, correctval, code...) \
test_ ## testnum: \
 code; \
 LOAD_CONSTANT(29, MASK_XLEN(correctval)); \
 li TESTNUM, testnum; \
 cmpw 29, testreg; \
 bne fail; \

#define TEST_CASE_DAT( testnum, testreg, correctdat, code... ) \
test_ ## testnum: \
    code; \
    li  %r28, correctdat; \
    lwz  %r29, 0(%r28); \
    li  TESTNUM, testnum; \
    cmpw 0, testreg, %r29; \
    bne 0, fail;

#define TEST_INSERT_NOPS_0
#define TEST_INSERT_NOPS_1  nop; TEST_INSERT_NOPS_0
#define TEST_INSERT_NOPS_2  nop; TEST_INSERT_NOPS_1
#define TEST_INSERT_NOPS_3  nop; TEST_INSERT_NOPS_2
#define TEST_INSERT_NOPS_4  nop; TEST_INSERT_NOPS_3
#define TEST_INSERT_NOPS_5  nop; TEST_INSERT_NOPS_4
#define TEST_INSERT_NOPS_6  nop; TEST_INSERT_NOPS_5
#define TEST_INSERT_NOPS_7  nop; TEST_INSERT_NOPS_6
#define TEST_INSERT_NOPS_8  nop; TEST_INSERT_NOPS_7
#define TEST_INSERT_NOPS_9  nop; TEST_INSERT_NOPS_8
#define TEST_INSERT_NOPS_10 nop; TEST_INSERT_NOPS_9

#-----------------------------------------------------------------------
# Tests for instructions with immediate operand
#-----------------------------------------------------------------------

#define SEXT_IMM(x) ((x) | (-(((x) >> 11) & 1) << 11))

#define TEST_IMM_OP( testnum, inst, result, val1, imm ) \
  TEST_CASE( testnum, 30, result, \
	     LOAD_CONSTANT(1, MASK_XLEN(val1));	\
	     inst 30, 1, SEXT_IMM(imm); \
	     )

#define TEST_IMM_SRC1_EQ_DEST( testnum, inst, result, val1, imm ) \
  TEST_CASE( testnum, 1, result, \
	     LOAD_CONSTANT(1, MASK_XLEN(val1));	\
	     inst 1, 1, SEXT_IMM(imm); \
	     )

#define TEST_IMM_DEST_BYPASS( testnum, nop_cycles, inst, result, val1, imm ) \
  TEST_CASE( testnum, 6, result, \
	     li  4, 0; \
  1:    LOAD_CONSTANT(1, MASK_XLEN(val1));	\
	     inst 30, 1, SEXT_IMM(imm); \
		   TEST_INSERT_NOPS_ ## nop_cycles \
	     addi  6, 30, 0; \
	     addi  4, 4, 1; \
	     li  5, 2; \
	     cmpw 4,5; \
	     bne 1b \
	     )

#define TEST_IMM_SRC1_BYPASS( testnum, nop_cycles, inst, result, val1, imm ) \
  TEST_CASE( testnum, 30, result, \
	     li  4, 0; \
  1:    LOAD_CONSTANT(1, MASK_XLEN(val1));	   \
		   TEST_INSERT_NOPS_ ## nop_cycles \
	     inst 30, 1, SEXT_IMM(imm); \
	     addi  4, 4, 1; \
	     li  5, 2; \
	     cmpw 4,5; \
	     bne 1b \
	     )

#define TEST_IMM_ZEROSRC1( testnum, inst, result, imm ) \
  TEST_CASE( testnum, 1, result, \
	     inst 1, 0, SEXT_IMM(imm); \
	     )

#-----------------------------------------------------------------------
# Tests for an instruction with register operands
#-----------------------------------------------------------------------

#define TEST_R_OP( testnum, inst, result, val1 ) \
  TEST_CASE( testnum, 30, result, \
	     LOAD_CONSTANT(1, val1); \
	     inst 30, 1; \
	     )

#define TEST_R_SRC1_EQ_DEST( testnum, inst, result, val1 ) \
  TEST_CASE( testnum, 1, result, \
	     LOAD_CONSTANT(1, val1) \
	     inst 1, 1; \
	     )

#define TEST_R_DEST_BYPASS( testnum, nop_cycles, inst, result, val1 ) \
  TEST_CASE( testnum, 6, result, \
	     li 4, 0; \
  1:    LOAD_CONSTANT(1, val1);			\
	     inst 30, 1; \
	     TEST_INSERT_NOPS_ ## nop_cycles \
	     addi  6, 30, 0; \
	     addi  4, 4, 1; \
	     li  5, 2; \
	     cmpw 4, 5; \
	     bne 1b \
	     )

#-----------------------------------------------------------------------
# Tests for an instruction with register-register operands
#-----------------------------------------------------------------------

#define TEST_RR_OP( testnum, inst, result, val1, val2 ) \
  TEST_CASE( testnum, 30, result, \
	     LOAD_CONSTANT(1, MASK_XLEN(val1));	\
	     LOAD_CONSTANT(2, MASK_XLEN(val2));	\
	     inst 30, 1, 2; \
	     )

#define TEST_RR_DAT( testnum, inst, result, dat1, dat2 ) \
    TEST_CASE_DAT( testnum, %r30, result, \
      li  %r4, dat1 ## @l; \
      lwz  %r1, 0(%r4); \
      li  %r4, dat2 ## @l; \
      lwz  %r2, 0(%r4); \
      inst %r30, %r1, %r2; \
    )

#define TEST_RR_SRC1_EQ_DEST( testnum, inst, result, val1, val2 ) \
  TEST_CASE( testnum, 1, result, \
	     LOAD_CONSTANT(1, MASK_XLEN(val1));	\
	     LOAD_CONSTANT(2, MASK_XLEN(val2));	\
	     inst 1, 1, 2; \
	     )

#define TEST_RR_SRC2_EQ_DEST( testnum, inst, result, val1, val2 ) \
  TEST_CASE( testnum, 2, result, \
	     LOAD_CONSTANT(1, MASK_XLEN(val1));	\
	     LOAD_CONSTANT(2, MASK_XLEN(val2));	\
	     inst 2, 1, 2; \
	     )

#define TEST_RR_SRC12_EQ_DEST( testnum, inst, result, val1 ) \
  TEST_CASE( testnum, 1, result, \
	     LOAD_CONSTANT(1, MASK_XLEN(val1));	\
	     inst 1, 1, 1; \
	     )

#define TEST_RR_DEST_BYPASS( testnum, nop_cycles, inst, result, val1, val2 ) \
  TEST_CASE( testnum, 6, result, \
	     li  4, 0; \
  1:    LOAD_CONSTANT(1, MASK_XLEN(val1));	\
	     LOAD_CONSTANT(2, MASK_XLEN(val2));	\
	     inst 30, 1, 2; \
		   TEST_INSERT_NOPS_ ## nop_cycles \
	     addi  6, 30, 0; \
	     addi  4, 4, 1; \
	     li  5, 2; \
	     cmpw 5, 4; \
	     bne 1b \
	     )

#define TEST_RR_SRC12_BYPASS( testnum, src1_nops, src2_nops, inst, result, val1, val2 ) \
  TEST_CASE( testnum, 30, result, \
	     li  4, 0; \
  1:    LOAD_CONSTANT(1, MASK_XLEN(val1));	\
	     TEST_INSERT_NOPS_ ## src1_nops	\
	     LOAD_CONSTANT(2, MASK_XLEN(val2));		\
			 TEST_INSERT_NOPS_ ## src2_nops \
	     inst 30, 1, 2; \
	     addi  4, 4, 1; \
	     li  5, 2; \
	     cmpw 5, 4; \
	     bne 1b \
	     )

#define TEST_RR_SRC21_BYPASS( testnum, src1_nops, src2_nops, inst, result, val1, val2 ) \
  TEST_CASE( testnum, 30, result, \
	     li 4, 0; \
  1:    LOAD_CONSTANT(2, MASK_XLEN(val2));	  \
	     TEST_INSERT_NOPS_ ## src1_nops		\
	LOAD_CONSTANT(1, MASK_XLEN(val1));		\
			 TEST_INSERT_NOPS_ ## src2_nops \
	     inst 30, 1, 2; \
	     addi  4, 4, 1; \
	     li  5, 2; \
	     cmpw 4, 5; \
	     bne 1b \
	     )

#define TEST_RR_ZEROSRC1( testnum, inst, result, val ) \
  TEST_CASE( testnum, 2, result, \
	     LOAD_CONSTANT(1, MASK_XLEN(val));	\
	     inst 2, 0, 1; \
	     )

#define TEST_RR_ZEROSRC2( testnum, inst, result, val ) \
  TEST_CASE( testnum, 2, result, \
	     LOAD_CONSTANT(1, MASK_XLEN(val));	\
	     inst 2, 1, 0; \
	     )

#define TEST_RR_ZEROSRC12( testnum, inst, result ) \
  TEST_CASE( testnum, 1, result, \
	     inst 1, 0, 0; \
	     )

#-----------------------------------------------------------------------
# Test memory instructions
#-----------------------------------------------------------------------

#define TEST_LD_OP( testnum, inst, result, offset, base ) \
  TEST_CASE( testnum, 30, result, \
	     LOAD_CONSTANT(1, base); \
	     inst 30, offset(1); \
	     )

#define TEST_ST_OP( testnum, load_inst, store_inst, result, offset, base ) \
  TEST_CASE( testnum, 30, result, \
	     LOAD_CONSTANT(1, base); \
	     LOAD_CONSTANT(2, result); \
	     store_inst 2, offset(1); \
	     load_inst 30, offset(1); \
	     )

#define TEST_LD_DEST_BYPASS( testnum, nop_cycles, inst, result, offset, base ) \
  test_ ## testnum: \
  li  TESTNUM, testnum; \
  li  4, 0; \
1: LOAD_CONSTANT(1, base); \
  inst 30, offset(1); \
      TEST_INSERT_NOPS_ ## nop_cycles \
      addi  6, 30, 0; \
      LOAD_CONSTANT(29, result); \
      cmpw 6,29; \
      bne fail; \
      addi  4, 4, 1; \
      li  5, 2; \
      cmpw 4, 5; \
      bne 1b \

#define TEST_LD_SRC1_BYPASS( testnum, nop_cycles, inst, result, offset, base ) \
  test_ ## testnum: \
  li  TESTNUM, testnum; \
  li  4, 0; \
1:  LOAD_CONSTANT(1, base);	      \
      TEST_INSERT_NOPS_ ## nop_cycles \
      inst 30, offset(1); \
      LOAD_CONSTANT(29, result);\
      cmpw 30, 29; \
      bne fail; \
      addi  4, 4, 1; \
      li  5, 2; \
      cmpw 4,5; \
      bne 1b	\

#define TEST_ST_SRC12_BYPASS( testnum, src1_nops, src2_nops, load_inst, store_inst, result, offset, base ) \
  test_ ## testnum: \
  li  TESTNUM, testnum; \
  li  4, 0; \
1:  LOAD_CONSTANT(1, result);	     \
      TEST_INSERT_NOPS_ ## src1_nops \
    LOAD_CONSTANT(2, base);		 \
	  TEST_INSERT_NOPS_ ## src2_nops \
	  store_inst 1, offset(2); \
	  load_inst 30, offset(2); \
	  LOAD_CONSTANT(29, result); \
	  cmpw 30, 29; \
	  bne fail; \
	  addi  4, 4, 1; \
	  li  5, 2; \
	  cmpw 4,5; \
	  bne 1b \

#define TEST_ST_SRC21_BYPASS( testnum, src1_nops, src2_nops, load_inst, store_inst, result, offset, base ) \
  test_ ## testnum:							\
  li  TESTNUM, testnum;				\
  li  4, 0;					\
1:  LOAD_CONSTANT(2, base);			\
  TEST_INSERT_NOPS_ ## src1_nops		\
  LOAD_CONSTANT(1, result);			\
  TEST_INSERT_NOPS_ ## src2_nops		\
  store_inst 1, offset(2);			\
  load_inst 30, offset(2);			\
  LOAD_CONSTANT(29, result);			\
  cmpw 30, 29;					\
  bne fail;					\
  addi 4, 4, 1;					\
  li  5, 2;					\
  cmpw 4,5;					\
  bne 1b					\

#define TEST_BR2_SRC12_BYPASS( testnum, src1_nops, src2_nops, inst, val1, val2 ) \
  test_ ## testnum: \
  li  TESTNUM, testnum; \
  li  4, 0; \
1:  LOAD_CONSTANT(1, val1);	     \
  TEST_INSERT_NOPS_ ## src1_nops     \
  LOAD_CONSTANT(2, val2);		 \
  TEST_INSERT_NOPS_ ## src2_nops	 \
  inst 1, 2, fail;			 \
  addi  4, 4, 1;			 \
  li  5, 2;				 \
  cmpw 4,5;				 \
  bne 1b				 \

#define TEST_BR2_SRC21_BYPASS( testnum, src1_nops, src2_nops, inst, val1, val2 ) \
  test_ ## testnum: \
  li  TESTNUM, testnum; \
  li  x4, 0; \
1:  li  x2, val2; \
      TEST_INSERT_NOPS_ ## src1_nops \
      li  x1, val1; \
	  TEST_INSERT_NOPS_ ## src2_nops \
	  inst x1, x2, fail; \
	  addi  x4, x4, 1; \
	  li  x5, 2; \
	  bne x4, x5, 1b \

#-----------------------------------------------------------------------
# Test fixed point vector instructions
#-----------------------------------------------------------------------

#define FXV_VERIFY_RESULT(res) \
  addi 6, 5, 0;	\
  LOAD_CONSTANT(8, res);				    \
  LOAD_CONSTANT(10, FXV_NUM_SLICES * FXV_BYTES_PER_SLICE) ; \
  add 11, 5, 10; \
1: add 12, 6, 4; \
  lwz 7,0(12); \
  cmpw 7, 8 ; \
  bne fail ; \
  addi 6, 6, 4 ; \
  cmpw 6, 11; \
  bne 1b \


#define TEST_FXV_RR_OP(testnum, inst, res, val1, val2, load_inst, store_inst, result_base) \
  TEST_CASE( testnum, 30, 1, \
	     LOAD_CONSTANT(1, val1);	\
	     LOAD_CONSTANT(2, val2);	\
	     LOAD_CONSTANT(4, result_base); \
	     LOAD_CONSTANT(5, testnum * FXV_NUM_SLICES * FXV_BYTES_PER_SLICE); \
	     load_inst 1, 1; \
	     load_inst 2, 2;	     \
	     inst 31, 1, 2; \
	     store_inst 31, 5, 4 ; \
	     sync; \
	     FXV_VERIFY_RESULT(res); \
	     li 30, 1 ; \
	     )


#define FXV_CHECK_EQUAL(lhs, rhs) \
	LOAD_CONSTANT(%r10, FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4); \
	mtctr %r10; \
	lwz %r11, 0(lhs); \
	lwz %r12, 0(rhs); \
	b 2f; \
1:	lwzu %r11, 4(lhs); \
	lwzu %r12, 4(rhs); \
2:	cmpw %r11, %r12 ; \
	bne fail; \
	bdnz 1b; \


#define TEST_FXV_C_RR_OP(testnum, inst, size, expected_base, val1, val2, mask_base, default, cond, result_base) \
	TEST_CASE( testnum, %r30, 1, \
		LOAD_CONSTANT(%r1, val1); \
		LOAD_CONSTANT(%r2, val2); \
		LOAD_CONSTANT(%r3, mask_base); \
		LOAD_CONSTANT(%r4, result_base + testnum * FXV_NUM_SLICES * FXV_BYTES_PER_SLICE); \
		LOAD_CONSTANT(%r5, expected_base); \
		LOAD_CONSTANT(%r6, default); \
		fxvsplat ## size 1, %r1; \
		fxvsplat ## size 2, %r2; \
		fxvlax 3, 0, %r3; \
		fxvsplat ## size 31, %r6; \
		fxvcmp ## size 3; \
		inst 31, 1, 2, cond; \
		fxvstax 31, 0, %r4; \
		sync; \
		FXV_CHECK_EQUAL(%r4, %r5); \
		li %r30, 1; \
	)

#define TEST_FXV_C_ACC_RR_OP(testnum, inst, size, expected_base, val1, val2, mask_base, default, acc, cond, result_base) \
	TEST_CASE( testnum, %r30, 1, \
		LOAD_CONSTANT(%r1, val1); \
		LOAD_CONSTANT(%r2, val2); \
		LOAD_CONSTANT(%r3, mask_base); \
		LOAD_CONSTANT(%r4, result_base + testnum * FXV_NUM_SLICES * FXV_BYTES_PER_SLICE); \
		LOAD_CONSTANT(%r5, expected_base); \
		LOAD_CONSTANT(%r6, acc); \
		LOAD_CONSTANT(%r7, default); \
		fxvsplat ## size 1, %r1; \
		fxvsplat ## size 2, %r2; \
		fxvlax 3, 0, %r3; \
		fxvsplat ## size 4, %r6; \
		fxvsplat ## size 31, %r7; \
		fxvmtac ## size 4; \
		fxvcmp ## size 3; \
		inst 31, 1, 2, cond; \
		fxvstax 31, 0, %r4; \
		sync; \
		FXV_CHECK_EQUAL(%r4, %r5); \
		li %r30, 1; \
	)


#define TEST_SYNRAM_INX_LOOP(testnum, obus_addr, inx_addr, data_base, result_base) \
	TEST_CASE( testnum, %r30, 1, \
		LOAD_CONSTANT(%r1, data_base); \
		LOAD_CONSTANT(%r2, obus_addr); \
		LOAD_CONSTANT(%r3, FXV_NUM_SLICES * FXV_BYTES_PER_SLICE / 4) \
		mtctr %r3; \
		lwzu %r4, 0(%r1); \
		stwu %r4, 0(%r2); \
		bdnz 1f; \
1:		lwzu %r4, 4(%r1); \
		stwu %r4, 4(%r2); \
		bdnz 1b; \
		LOAD_CONSTANT(%r1, inx_addr); \
		LOAD_CONSTANT(%r2, result_base); \
		sync; \
		fxvinx 1, 0, %r1; \
		fxvstax 1, 0, %r2; \
		sync; \
		LOAD_CONSTANT(%r1, data_base); \
		FXV_CHECK_EQUAL(%r1, %r2); \
		li %r30, 1; \
	)

#define TEST_FXVIO_CONFLICT(testnum, veca, vecb, indexa, indexb, resa, resb) \
	TEST_CASE( testnum, %r30, 1, \
		LOAD_CONSTANT(%r1, veca); \
		LOAD_CONSTANT(%r2, vecb); \
		fxvlax 1, 0, %r1; \
		fxvlax 2, 0, %r2; \
		LOAD_CONSTANT(%r3, indexa); \
		LOAD_CONSTANT(%r4, indexb); \
		fxvoutx 1, 0, %r3; \
		fxvoutx 2, 0, %r4; \
		fxvinx 30, 0, %r3; \
		fxvinx 31, 0, %r4; \
		LOAD_CONSTANT(%r3, resa); \
		LOAD_CONSTANT(%r4, resb); \
		fxvstax 30, 0, %r3; \
		fxvstax 31, 0, %r4; \
		sync; \
		FXV_CHECK_EQUAL(%r1, %r3); \
		FXV_CHECK_EQUAL(%r2, %r4); \
		li %r30, 1; \
	)

/* #define TEST_FXV_RR_MASKED_OP(testnum, inst, val1, val2, load_inst, store_inst, mask_base, expected_base, result_base) \ */
/*   TEST_CASE( testnum, 30, 1,						\ */
/*     LOAD_CONSTANT(1, val1); \ */
/*     LOAD_CONSTANT(2, val2); \ */
/*     LOAD_CONSTANT(4, result_base);					\ */
/*     LOAD_CONSTANT(5, expected_base);					\ */
/*     LOAD_CONSTANT(6, mask_base);					\ */
/*     LOAD_CONSTANT(7, testnum * FXV_NUM_SLICES * FXV_BYTES_PER_SLICE);	\ */
/*     load_inst  */
/*     load_inst 1, 1; \ */
/*     load_inst 2, 2; \ */
/*     inst 31, 1, 2; \ */




#define TEST_PASSFAIL \
	      cmpw 0, TESTNUM; \
	      bne pass; \
fail: \
 PPCTEST_FAIL; \
pass: \
 PPCTEST_PASS \

#endif
