objects = my_print.o
main: my_print.o
	gcc -m32 main.c my_print.o

my_print.o : my_print.asm
	nasm -f elf32 my_print.asm
#main: main.c my_print.o
#	gcc -m32 main.c my_print.o
.PHONY : clean
clean :
	rm main $(objects)
