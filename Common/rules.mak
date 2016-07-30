######################################################################
# Common build rules

all: dirs $(BIN)/$(TARG)

######################################################################

dirs:
	@echo Creating directories...
	@-mkdir $(BUILD) 2>/dev/null || true
	@-mkdir $(BIN) 2>/dev/null || true
	@-ln -s ../ROMs 2>/dev/null || true

######################################################################

$(TARG): $(BIN)/$(TARG)
.PHONY: $(TARG)

$(BIN)/$(TARG): dirs $(OBJS)
	@echo Link $@
	@$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS)

######################################################################

$(BUILD)/z80.o:		$(ORIGSRC)/defs.h $(ORIGSRC)/z80.c
$(BUILD)/disassem.o:	$(ORIGSRC)/defs.h $(ORIGSRC)/disassem.c
$(BUILD)/main.o:	$(ORIGSRC)/defs.h $(ORIGSRC)/main.c
$(BUILD)/iomem.o:	$(ORIGSRC)/defs.h $(SRC)/iomem.c
$(BUILD)/memregion.o:	$(ORIGSRC)/defs.h $(COMMONSRC)/memregion.c
$(BUILD)/m6850_console.o:	$(ORIGSRC)/defs.h $(COMMONSRC)/6850_console.c

######################################################################

$(BUILD)/%.o: $(ORIGSRC)/%.c
	@echo $@
	@$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/%.o: $(COMMONSRC)/%.c
	@echo $@
	@$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/%.o: $(SRC)/%.c
	@echo $@
	@$(CC) $(CFLAGS) -c -o $@ $<

######################################################################

clean:
	@echo Removing transient files...
	@-rm -rf $(BIN)/ $(BUILD)/ ROMs

.PHONY: clean

######################################################################

test: $(BIN)/$(TARG)
	@echo Testing $(TARG)
	@./$(BIN)/$(TARG)

.PHONY: test
