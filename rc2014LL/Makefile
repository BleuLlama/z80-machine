# Makefile for the RC2014 emulator
#  This relies heavily on the Common/ includes

TARG := rc2014ll

include ../Common/defs.mak

# additional defs
CFLAGS += -DAUTORUN -DFILTER_CONSOLE

SRCS += $(SRC)/storge.c
OBJS += $(BUILD)/storage.o

include ../Common/rules.mak

# additional rules
$(BUILD)/m6850_xxx.o:	$(ORIGSRC)/defs.h $(COMMONSRC)/6850_xxx.c

$(BUILD)/storage.o:	$(ORIGSRC)/defs.h $(SRC)/storage.c

# additional content for 'all' target...
all:
	@echo Creating SD Card content...
	@-ln -s ../ROMs SD_DISK/ 2>/dev/null || true

