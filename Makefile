tests := load_immediate add 

.PHONY: all
.PRECIOUS: %.elf

all: $(patsubst %,%.bin, $(tests))
	@for x in $(tests) ; do echo "$$x 0 0" ; done > testcases

%.o: %.s
	@powerpc-eabi-as --warn -mnux $< -o $@

%.elf: %.o
	@powerpc-eabi-ld -T link.ld $< -o $@

%.bin: %.elf
	@powerpc-eabi-objcopy -O binary $< $@

clean:
	remove testcases
