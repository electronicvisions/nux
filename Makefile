simple_tests := simple load_immediate
arithmetic_tests := add \
	and \
	or \
	xor \
	sub \
	srw \
	slw \
	addi \
	ori \
	mulw \
	mulhw \
	mullw \
	divw \
	divu

vector_tests := \
	fxvaddhm \
	fxvaddhm_c \
	fxvmulhm_c \
	fxvinx \
	fxvio \
	fxvsubhm \
	fxvsubhm_c \
	fxvaddbm \
	fxvaddbm_c \
	fxvmabm_c \
	fxvmulbm \
	fxvmulbm_c \
	fxvsubbm_c

failing_tests := \
	external_vector_access \
	external_memory_access
#	load_test \
#	load_immediate \
#	xori \


load_store_tests := \
	lwz \
	stw

tests := $(failing_tests) $(vector_tests) $(arithmetic_tests) $(load_store_tests)

.SUFFIXES: # Disable default rules
.PHONY: all
.PRECIOUS: %.elf %.pre.S # Don't delete generated elf and the preprocessor results files

all: $(patsubst %,%.bin, $(tests))
# write test names into testcases file, so that they get executed automatically
	@for x in $(tests) ; do echo "$$x 0 0" ; done > testcases

%.pre.S: %.S ppc_test.h test_macros.h
	@powerpc-eabi-cpp $< -o $@

%.o: %.pre.S
	@powerpc-eabi-as -mnux $< -o $@

%.elf: %.o
	@powerpc-eabi-ld -T link.ld $< -o $@

%.bin: %.elf
	@powerpc-eabi-objcopy -O binary $< $@

clean:
	@rm testcases
	@rm *.elf
	@rm *.pre.S
	@rm *.bin
