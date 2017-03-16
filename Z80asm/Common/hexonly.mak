#rom makefile to use Scott Lawrence's "Genroms" tool to build 
# rom files from the intel hex file

TARGLST := $(TARGBASE).lst

ROMSDIR := ../../prg/ROMs

GENFILES := \
		$(TARGBASE).lst \
		$(TARGBASE).ihx $(TARGBASE).hex \
		$(TARGBASE).rel $(TARGBASE).map 

################################################################################
# build rules

all: $(ROMSDIR) $(TARGBASE).ihx
	@echo "+ copy $(TARGBASE).hex to ROMS directory"
	@cp $(TARGBASE).ihx $(ROMSDIR)/$(TARGBASE).hex

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
