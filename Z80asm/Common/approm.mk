# makefile to use Scott Lawrence's "Genroms" tool to build 
# rom files from the intel hex file

TARGROM := $(TARGBASE).rom

ROMSDIR := ../../prg/ROMs
BASDIR  := ../../prg/BASIC

ROMDEF  := ../Common/rc2014.roms

GENFILES := \
		$(TARGROM) \
		$(TARGBASE).lst \
		$(TARGBASE).ihx $(TARGBASE).hex \
		$(TARGBASE).rel $(TARGBASE).map 

################################################################################
# build rules

all: $(TARGROM) $(TARGBASE).hex $(ROMSDIR)
	@echo "+ copy $(TARGROM) to ROMs directory"
	@cp $(TARGROM) $(ROMSDIR)
	@cp $(TARGBASE).hex $(ROMSDIR)

$(TARGROM): $(TARGBASE).ihx
	@echo "+ genroms $<"
	@genroms $(ROMDEF) $<
	@mv rc2014.rom $@

$(ROMSDIR):
	@echo "+ Creating roms directory"
	@-mkdir $(ROMSDIR)

%.hex: %.ihx
	@echo "+ rename IHX as HEX"
	@cp $< $@

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
