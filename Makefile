# Makefile for RC2014 projects

PROJDIRS := \
	Z80asm \
	\
	rc2014 \
	rc2014LL \
	rc2014SB 

all:	emus

emus:
	@echo "Building Projects"
	for dir in $(PROJDIRS); do \
               $(MAKE) -C $$dir; \
             done
clean:
	@echo "Cleaning up all products"
	for dir in $(PROJDIRS); do \
               $(MAKE) -C $$dir clean; \
             done
