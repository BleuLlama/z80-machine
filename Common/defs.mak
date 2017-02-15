# common build definitions

TARG ?= rc2014_emu
BUILD := ./build
BIN := ./bin
SRC := ./src
ORIGSRC := ../z80orig/src
COMMONSRC := ../Common/src
CC := gcc
CFLAGS := -O2 -pipe -Wall -DPOSIX_TTY -DLITTLE_ENDIAN -DMEM_BREAK \
	  -I$(ORIGSRC) -I$(COMMONSRC) -I$(SRC) \
	  -DEXTERNAL_IO -DEXTERNAL_MEM \
	  -DSYSTEM_POLL \
	  -Wall -pedantic \
	  -Wno-pointer-sign -Wno-int-to-pointer-cast \
	  \
	  -Wno-strict-aliasing \
	  -std=c99 

UNUSED_CFLAGS := -DAUTORUN -DRAW_TERM

LDFLAGS := 

SRCS := \
	$(ORIGSRC)/z80.c \
	$(ORIGSRC)/disassem.c \
	$(ORIGSRC)/main.c \
	$(COMMONSRC)/host.c \
	$(COMMONSRC)/memregion.c \
	$(COMMONSRC)/ioports.c \
	$(COMMONSRC)/mc6850_console.c \
	$(SRC)/system.c 

OBJS := $(addprefix $(BUILD)/, $(notdir $(SRCS:%.c=%.o) ) )

