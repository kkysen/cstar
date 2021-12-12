CC := gcc
CFLAGS := -Wall -g
OBJS := println.o 
DEPENDS := println.h

libcstar.a: stdlib
		ar -cq libcstar.a *.o 
		rm -f *.o 

stdlib: $(OBJS)

%.o: %.c $(DEPENDS)
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f *.o *.a

all: clean libcstar.a 

.PHONY: clean all