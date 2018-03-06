ENTRY(_start)

MEMORY {
	ram (rwx) : ORIGIN = 0, LENGTH = 16K
	external_ram (rwx) : ORIGIN = (1<<31), LENGTH = 100M
}


SECTIONS {
	.text : {
		*(.text)
	} > ram

	.data : {
		*(.data)
		*(.rodata)
	} > ram

	.bss  : {
		*(.bss)
		*(.sbss)
	} > ram

	_end = .;
}
