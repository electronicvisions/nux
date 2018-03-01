	#include "chip_constants.h"
	#include "test_macros.h"
	.text
	.global _start
_start:
	lis 1, (1<<30)@h
	ori 1,1, (1<<30)@l
	li 2,0xff
	stw 2,0(1)
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	wait
