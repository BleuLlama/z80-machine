# makefile to use Scott Lawrence's "Genroms" tool to build 
# rom files from the intel hex file

TARGROM := $(TARGBASE).rom
SOURCEHEX := $(HEXBASE).hex

GENFILES := $(TARGROM) 
ROMSDIR := ../../prg/ROMs

################################################################################
# build rules

all: $(TARGROM) $(HEXBASE).hex $(ROMSDIR)
	@echo "+ copy $(TARGROM) to ROMs directory"
	@cp $(TARGROM) $(ROMSDIR)
	@cp $(SOURCEHEX) $(ROMSDIR)/$(TARGBASE).hex

$(TARGROM): $(SOURCEHEX)
	@echo "+ genroms $<"
	@genroms ../Common/rc2014.roms $<
	@mv rc2014.rom $@

$(ROMSDIR):
	@echo "+ Creating roms directory"
	@-mkdir $(ROMSDIR)

################################################################################

clean:
	@echo "+ Cleaning directory " $(TARGBASE)
	@-rm $(GENFILES) 2>/dev/null || true

