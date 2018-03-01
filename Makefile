tests := load_immediate add external_memory_access

.SUFFIXES: # Disable default rules
.PHONY: all
.PRECIOUS: %.elf # Don't delete generated elf files

all: $(patsubst %,%.bin, $(tests))
# write test names into testcases file, so that they get executed automatically
	@for x in $(tests) ; do echo "$$x 0 0" ; done > testcases

%.o: %.S test_macros.h
	@powerpc-eabi-as -mnux $< -o $@

%.elf: %.o
	@powerpc-eabi-ld -T link.ld $< -o $@

%.bin: %.elf
	@powerpc-eabi-objcopy -O binary $< $@

clean:
	@rm testcases
	@rm *.elf
	@rm *.bin
