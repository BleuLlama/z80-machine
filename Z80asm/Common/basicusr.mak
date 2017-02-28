#rom makefile to use Scott Lawrence's "Genroms" tool to build 
# rom files from the intel hex file

TARGLST := $(TARGBASE).lst
TARGBAS := $(TARGBASE).bas

ROMSDIR := ../../prg/ROMs
BASDIR  := ../../prg/BASIC

TOPRAM ?= F8

GENFILES := \
		$(TARGBASE).bas \
		$(TARGBASE).lst \
		$(TARGBASE).ihx $(TARGBASE).hex \
		$(TARGBASE).rel $(TARGBASE).map 

################################################################################
# build rules

all: $(TARGBAS)
	@echo "+ copy $(TARGBAS) to BASIC directory"
	@cp $(TARGBAS) $(BASDIR)

$(TARGBAS): $(TARGBASE).ihx
	@echo "+ generate BASIC program from $(TARGLST)"
	@../Common/basicusr.pl $(TARGLST) $(TARGBAS) $(TOPRAM) AUTORUN

$(BASDIR):
	@echo "+ Creating basic directory"
	@-mkdir $(BASDIR)

$(ROMSDIR):
	@echo "+ Creating roms directory"
	@-mkdir $(ROMSDIR)

%.ihx: %.rel %.map
	@echo "+ aslink $@"
	@aslink -i -m -o $@ $<

%.rel %.map %.lst: %.asm
	@echo "+ asz80 $<"
	@asz80 -l $<

################################################################################

clean:
	@echo "+ Cleaning directory " $(TARGBASE)
	@-rm $(GENFILES) 2>/dev/null || true
