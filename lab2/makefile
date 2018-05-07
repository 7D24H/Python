# this is make file

objects = try.o

try: $(objects)
	gcc -o try $(objects)
try.o:try.c
	gcc -c -o try.o try.c
.PHONY:clean
clean:
	rm try $(objects)

