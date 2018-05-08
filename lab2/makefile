objects = asmPrint.o
main: asmPrint.o
	gcc -m32 main.c asmPrint.o

asmPrint.o : asmPrint.asm
	nasm -f elf32 asmPrint.asm
#main: main.c asmPrint.o
#	gcc -m32 main.c asmPrint.o
.PHONY : clean
clean :
	rm main $(objects)
