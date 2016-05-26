# Makefile for RC2014/LL

ROMSDIR := ../ROMs


all:	roms

ROMDIRS := \
	lloader \
	basic.32 \
	basic.56 \
	smalltest \
	iotest


roms: romdir
	@echo "Building ROMs"
	for dir in $(ROMDIRS); do \
               $(MAKE) -C $$dir; \
             done
romdir:
	@echo "Creating ROM directory"
	@-mkdir $(ROMSDIR)

clean:
	@echo "Cleaning up all products"
	-rm -rf ROMs
	for dir in $(ROMDIRS); do \
               $(MAKE) -C $$dir clean; \
             done

test:	all
	./rc2014sim
