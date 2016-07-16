#rom makefile to use Scott Lawrence's "Genroms" tool to build 
# rom files from the intel hex file

TARGROM := $(TARGBASE).rom
TARGLST := $(TARGBASE).lst

ROMSDIR := ../../ROMs
ROMDEF  := ../Common/basicusr.roms

GENFILES := \
		$(TARGROM) \
		$(TARGBASE).lst \
		$(TARGBASE).ihx $(TARGBASE).hex \
		$(TARGBASE).rel $(TARGBASE).map 

################################################################################
# build rules

all: $(TARGROM)
	@echo "+ generate BASIC program from $(TARGLST)"
	@../Common/basicusr.pl $(TARGLST)

$(TARGROM): $(TARGBASE).ihx
	@echo "+ genroms $<"
	@genroms $(ROMDEF) $<
	@mv basicusr.rom $@

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
