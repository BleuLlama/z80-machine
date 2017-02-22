# Makefile for RC2014/LL

ROMSDIR := ../ROMs


all:	roms

ROMDIRS := \
	baslload \
	selftest \
	basic.32 \
	basic.56 

OLDDIRS: = \
	smalltest \
	aciatest \
	iotest


roms: 
	@echo "Building ROMs"
	for dir in $(ROMDIRS); do \
               $(MAKE) -C $$dir; \
             done

clean:
	@echo "Cleaning up all products"
	-rm -rf $(ROMSDIR)/*
	for dir in $(ROMDIRS); do \
               $(MAKE) -C $$dir clean; \
             done

test:	all
	./rc2014sim
