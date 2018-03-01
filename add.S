#include "test_macros.h"
#include "chip_constants.h"

	.text
	.global _start
_start:
	li 1,1
	li 2,2
	li 3,3
	li 4,4
	li 5,5
	li 6,6
	li 7,7
	li 8,8
	li 9,9
	li 10,10
	li 11,11
	li 12,12
	li 13,13
	li 14,14
	li 15,15
	li 16,16
	li 17,17
	li 18,18
	li 19,19
	li 20,20
	li 21,21
	li 22,22
	li 23,23
	li 24,24
	li 25,25
	li 26,26
	li 27,27
	li 28,28
	li 29,29
	li 30,30
	li 31,31
	add 3,2,1
	add 6,5,4
	add 9,8,7
	add 12,11,10
	add 15,14,13
	add 18,17,16
	add 21,20,19
	add 24,23,22
	add 27,26,25
	add 30,29,28
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	lis 3,mail@ha
	addi 3,3,mail@l
	lwz 16, 4*0(3)
	lwz 17, 4*1(3)
	lwz 18, 4*2(3)
	lwz 19, 4*3(3)
	lwz 20, 4*4(3)
	nop
	nop
	nop
	stw 19,0(20)
	nop
	nop
	wait

.data
mail: .long 0xffff,0xeeee,0xaaaa,0xbbbb,4*200
