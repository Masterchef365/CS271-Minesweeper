name ?= minesweeper
source := $(name).s
program_name ?= $(name)
list_file := $(name).lst
asm_obj := $(name).o

.PHONY: all clean run

$(asm_obj):
	yasm -g dwarf2 -l $(list_file) -f elf32 $(source) -o $(asm_obj) 

$(program_name): $(asm_obj)
	gcc -static -o $(program_name) $(asm_obj) /home/duncan/Downloads/Along32/src/Along32.o -m32

all: $(program_name)

run: $(program_name)
	./$(program_name)

debug: $(program_name)
	cgdb -- $(program_name) run -ex start

clean:
	rm -f $(program_name) $(asm_obj) $(list_file)

dump: $(program_name)
	readelf -x .data $(program_name)
	objdump -d $(program_name) -M intel
