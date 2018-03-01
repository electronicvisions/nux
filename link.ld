ENTRY(_start)

MEMORY {
	ram (rwx) : ORIGIN = 0, LENGTH = 16K
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
