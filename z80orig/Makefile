# optional CFLAGS include: -O -g -Wall
# -DNO_LARGE_SWITCH	compiler cannot handle really big switch statements
#			so break them into smaller pieces
# -DLITTLE_ENDIAN	machine's byte-sex is like x86 instead of 68k
# -DPOSIX_TTY		use Posix termios instead of older termio (FreeBSD)
# -DMEM_BREAK		support memory-mapped I/O and breakpoints,
#				which will noticably slow down emulation

BIN ?= ./bin
SRC = ./src
MAC = ./mac
DRIVES = ./drives
UTILS = ./utils
CC = gcc
CFLAGS = -O2 -pipe -Wall -DPOSIX_TTY -DLITTLE_ENDIAN -DMEM_BREAK \
	 -Wno-pointer-sign -Wno-int-to-pointer-cast -DBUILD_CPM -Wimplicit-function-declaration
OLD_CFLAGS = -ansi
LDFLAGS = 

FILES = README Makefile $(MAC)/MacProj.hqx z80.proj \
	$(DRIVES)/A-Hdrive.gz	\
	$(SRC)/cpmdisc.h $(SRC)/defs.h	\
	$(SRC)/cpm.c $(SRC)/bios.c $(SRC)/disassem.c $(SRC)/main.c $(SRC)/z80.c	\
	$(SRC)/makedisc.c \
	$(UTILS)/bye.mac $(UTILS)/getunix.mac $(UTILS)/putunix.mac

OBJS =	$(SRC)/bios.o \
	$(SRC)/disassem.o \
	$(SRC)/main.o \
	$(SRC)/z80.o

all: dirs cpm z80

dirs:
	-mkdir bin

cpm: $(BIN)/cpm

z80: $(BIN)/z80

$(BIN)/z80: $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(BIN)/z80 $(OBJS)

$(BIN)/cpm: $(BIN)/z80
	rm -f $(BIN)/cpm
	ln -s z80 $(BIN)/cpm

bios.o:		$(SRC)/bios.c $(SRC)/defs.h $(SRC)/cpmdisc.h $(SRC)/cpm.c
z80.o:		$(SRC)/z80.c $(SRC)/defs.h
disassem.o:	$(SRC)/disassem.c $(SRC)/defs.h
main.o:		$(SRC)/main.c $(SRC)/defs.h

clean:
	rm -f $(BIN)/z80 $(BIN)/cpm $(SRC)/*.o

tags:	$(FILES)
	cxxtags *.[hc]

tar:
	tar -zcf z80.tgz $(FILES) p2dos zcpr1 zmac

files:
	@echo $(FILES)

difflist:
	@for f in $(FILES); do rcsdiff -q $$f >/dev/null || echo $$f; done

.PHONY: cpm z80
