	#include "test_macros.h"
	#include "ppc_test.h"
	.text
	.global _start
_start:
	LOAD_CONSTANT(%r1, (1<<31))
	LOAD_CONSTANT(%r2, FXV_NUM_SLICES * FXV_BYTES_PER_SLICE)
	LOAD_CONSTANT(%r3, 0)
	LOAD_CONSTANT(%r4, 32)
	LOAD_CONSTANT(%r5, 0x0a)
	fxvsplatb 1, %r5
write_loop:
	fxvoutx 1, 0, %r1
	add %r1, %r1, %r2
	addi %r3, %r3, 1
	cmpw %r3, %r4
	bne write_loop
	LOAD_CONSTANT(%r1, (1<<31))
	LOAD_CONSTANT(%r2, FXV_NUM_SLICES * FXV_BYTES_PER_SLICE)
	LOAD_CONSTANT(%r3, 0)
	LOAD_CONSTANT(%r4, 32)
read_loop:
	fxvinx 1, 0, %r1
	add %r1, %r1, %r2
	addi %r3, %r3, 1
	cmpw %r3, %r4
	bne read_loop
	wait
