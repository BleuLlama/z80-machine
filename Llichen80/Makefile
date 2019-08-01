# Makefile for the RC2014 emulator
#  This relies heavily on the Common/ includes

TARG := llichen80emu

include ../Common/defs.mak

# additional defs
CFLAGS += -DAUTORUN -DFILTER_CONSOLE -DRESET_HANDLER

SRCS += $(SRC)/filter.c

OBJS += $(BUILD)/filter.o \
	$(BUILD)/filter_storage.o

include ../Common/rules.mak

# additional rules
$(BUILD)/m6850_xxx.o:	$(ORIGSRC)/defs.h $(COMMONSRC)/6850_xxx.c

$(BUILD)/filter.o:	$(ORIGSRC)/defs.h $(SRC)/filter.c
$(BUILD)/filter_storage.o:	$(ORIGSRC)/defs.h $(SRC)/filter_storage.c

# additional content for 'all' target...
all:
	@echo Creating Mass Storage content...
	@-rm MASS_DRV 2>/dev/null || true
	@-ln -s ../prg MASS_DRV 2>/dev/null || true

