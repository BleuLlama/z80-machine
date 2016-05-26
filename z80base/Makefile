
TARG := z80emu

BUILD := ./build
BIN := ./bin
SRC := ./src
ORIGSRC := ../z80orig/src
CC := gcc
CFLAGS := -O2 -pipe -Wall -DPOSIX_TTY -DLITTLE_ENDIAN -DMEM_BREAK \
	  -I$(ORIGSRC) \
	  -DEXTERNAL_IO -DEXTERNAL_MEM \
	  -DSYSTEM_POLL \
	  -Wno-pointer-sign -Wno-int-to-pointer-cast 
LDFLAGS := 


SRCS := \
	$(ORIGSRC)/z80.c \
	$(ORIGSRC)/disassem.c \
	$(ORIGSRC)/main.c \
	$(SRC)/iomem.c 

OBJS := $(addprefix $(BUILD)/, $(notdir $(SRCS:%.c=%.o) ) )

all: dirs $(BIN)/$(TARG)

dirs:
	@-mkdir $(BUILD) 2>&1
	@-mkdir $(BIN) 2>&1

$(TARG): $(BIN)/$(TARG)

$(BIN)/$(TARG): dirs $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS)

$(BUILD)/z80.o:		$(ORIGSRC)/defs.h $(ORIGSRC)/z80.c
$(BUILD)/disassem.o:	$(ORIGSRC)/defs.h $(ORIGSRC)/disassem.c
$(BUILD)/main.o:	$(ORIGSRC)/defs.h $(ORIGSRC)/main.c
$(BUILD)/iomem.o:	$(ORIGSRC)/defs.h $(SRC)/iomem.c


$(BUILD)/%.o: $(ORIGSRC)/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/%.o: $(SRC)/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	-rm -rf $(BIN)/ $(BUILD)/

.PHONY: $(TARG)


test: $(BIN)/$(TARG)
	./$(BIN)/$(TARG)

.PHONY: test
