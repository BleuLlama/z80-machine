
TARG := z80emu

BIN ?= ./bin
SRC := ./src
ORIGSRC := ../z80orig/src
CC := gcc
CFLAGS := -O2 -pipe -Wall -DPOSIX_TTY -DLITTLE_ENDIAN -DMEM_BREAK \
	  -I$(ORIGSRC) \
	  -Wno-pointer-sign -Wno-int-to-pointer-cast 
LDFLAGS := 

OBJS :=	\
	build/disassem.o \
	build/main.o \
	build/z80.o

all: dirs $(TARG)

dirs:
	@-mkdir build 2>&1
	@-mkdir bin 2>&1

$(TARG): $(BIN)/$(TARG)

$(BIN)/$(TARG): dirs $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS)

build/z80.o:		$(ORIGSRC)/defs.h $(ORIGSRC)/z80.c
build/disassem.o:	$(ORIGSRC)/defs.h $(ORIGSRC)/disassem.c
build/main.o:		$(ORIGSRC)/defs.h $(ORIGSRC)/main.c

clean:
	-rm -f $(BIN)/$(TARG) build/

.PHONY: $(TARG)


test: $(BIN)/$(TARG)
	./$(BIN)/$(TARG)

.PHONY: test
