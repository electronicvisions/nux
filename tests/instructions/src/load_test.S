#include "test_macros.h"

	.text
	.global _start
_start:
	LOAD_CONSTANT(1,tdat)
	lwz 2, 0(1)
	lwz 3, 4(1)
	lwz 4, 8(1)
	lwz 5, 12(1)
	lwz 6, 16(1)
	wait

tdat:
.long 0x00ff00ff, 0xff00ff00, 0xc0febabe, 0xdeadbeef, 0xbaadf00d
