# Makefile for the RC2014 emulator
#  This relies heavily on the Common/ includes

TARG := rc2014

include ../Common/defs.mak

# additional defs
CFLAGS += 

SRCS += $(SRC)/storge.c
OBJS += $(BUILD)/storage.o

include ../Common/rules.mak

# additional rules
$(BUILD)/m6850_xxx.o:	$(ORIGSRC)/defs.h $(COMMONSRC)/6850_xxx.c

$(BUILD)/storage.o:	$(ORIGSRC)/defs.h $(SRC)/storage.c
