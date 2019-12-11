# See LICENSE for license details

#include "test_macros.h"

.text
.global _start
_start:
	LOAD_CONSTANT(1, (1<<31))
	mtspr 8,1
	nop
	nop
	nop
	nop
	blr
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
