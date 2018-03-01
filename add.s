.macro  load_constant rD, const
.if (\const >= -0x8000) && (\const <= 0x7fff)
li      \rD, \const
.else
lis     \rD, \const@h
ori     \rD, \rD, \const@l
.endif
.endm

.text
.global _start
_start:
	load_constant 1, 0xffef
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
	stw 3,4*0(0)
	stw 6,4*1(0)
	stw 9,4*2(0)
	stw 12,4*3(0)
	stw 15,4*4(0)
	stw 18,4*5(0)
	stw 21,4*6(0)
	stw 24,4*7(0)
	stw 27,4*8(0)
	stw 30,4*9(0)
	nop
	nop
	lis 3,mail@ha
	addi 3,3,mail@l
	lwz 16, 272+4*0(0)
	lwz 17, 272+4*1(0)
	lwz 18, 272+4*2(0)
	lwz 19, 272+4*3(0)
	lwz 20, 272+4*4(0)
	nop
	nop
	nop
	stw 19,0(20)
	nop
	nop
	wait

.data
mail: .long 0xffff,0xeeee,0xaaaa,0xbbbb,4*200
