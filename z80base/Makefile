
TARG := z80emu

BIN ?= ./bin
SRC := ./src
CC := gcc
CFLAGS := -O2 -pipe -Wall -DPOSIX_TTY -DLITTLE_ENDIAN -DMEM_BREAK \
	 -Wno-pointer-sign -Wno-int-to-pointer-cast 
LDFLAGS := 

OBJS :=	\
	$(SRC)/disassem.o \
	$(SRC)/main.o \
	$(SRC)/z80.o

all: dirs $(TARG)

dirs:
	@-mkdir bin 2>&1

$(TARG): $(BIN)/$(TARG)

$(BIN)/$(TARG): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS)

z80.o:		$(SRC)/defs.h $(SRC)/z80.c
disassem.o:	$(SRC)/defs.h $(SRC)/disassem.c
main.o:		$(SRC)/defs.h $(SRC)/main.c

clean:
	-rm -f $(BIN)/$(TARG) $(SRC)/*.o

.PHONY: $(TARG)


test: $(BIN)/$(TARG)
	./$(BIN)/$(TARG)

.PHONY: test
