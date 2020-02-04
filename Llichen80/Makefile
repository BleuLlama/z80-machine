# Makefile for the RC2014 emulator
#  This relies heavily on the Common/ includes

TARG := llichen80emu

include ../Common/defs.mak

# additional defs
CFLAGS += -DAUTORUN -DRESET_HANDLER 

#CFLAGS += -DMC6850_SOCKET
# no -DFILTER_CONSOLE

# If you don't define this, it goes all-out. (100% usage of a cpu core)
CFLAGS += -DNICE_CPU=60000

# if this is defined, this is how many cycles are run per loop
# if this isn't defined, it defaults to 100000
CLFAGS += -D=CYCLES_PER_LOOP=50000

# 1000/100000 = 97%
# 90000/100000 = 65%
# 999999/100000 = 12% but unusable
# 40000/10000 = 76%
# 60000/50000 = 70% - pretty good performance too

# The above two should let you tune it to work like the "real thing", or
# at least get it working more efficiently

SRCS += $(SRC)/filter.c

OBJS += $(BUILD)/filter.o \
	$(BUILD)/filter_storage.o

include ../Common/rules.mak

# additional rules
$(BUILD)/m6850_xxx.o:	$(ORIGSRC)/defs.h $(COMMONSRC)/6850_xxx.c

$(BUILD)/filter.o:	$(ORIGSRC)/defs.h $(SRC)/filter.c
$(BUILD)/filter_storage.o:	$(ORIGSRC)/defs.h $(SRC)/filter_storage.c

# additional content for 'all' target...
all_withMassStorage:
	@echo Creating Mass Storage content...
	@-rm MASS_DRV 2>/dev/null || true
	@-ln -s ../prg MASS_DRV 2>/dev/null || true

