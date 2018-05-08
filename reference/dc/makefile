# this is make file

objects = main.o

main: $(objects)
	gcc -o main $(objects)
main.o:main.c
	gcc -c -o main.o main.c
.PHONY:clean
clean:
	rm main $(objects)

