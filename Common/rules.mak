# Common build rules

all: dirs $(BIN)/$(TARG)

dirs:
	@-mkdir $(BUILD) 2>&1
	@-mkdir $(BIN) 2>&1
	@-ln -s ../ROMs

$(TARG): $(BIN)/$(TARG)

$(BIN)/$(TARG): dirs $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS)

$(BUILD)/z80.o:		$(ORIGSRC)/defs.h $(ORIGSRC)/z80.c
$(BUILD)/disassem.o:	$(ORIGSRC)/defs.h $(ORIGSRC)/disassem.c
$(BUILD)/main.o:	$(ORIGSRC)/defs.h $(ORIGSRC)/main.c
$(BUILD)/iomem.o:	$(ORIGSRC)/defs.h $(SRC)/iomem.c
$(BUILD)/memregion.o:	$(ORIGSRC)/defs.h $(COMMONSRC)/memregion.c
$(BUILD)/m6850_console.o:	$(ORIGSRC)/defs.h $(COMMONSRC)/6850_console.c


$(BUILD)/%.o: $(ORIGSRC)/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/%.o: $(COMMONSRC)/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/%.o: $(SRC)/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	-rm -rf $(BIN)/ $(BUILD)/

.PHONY: $(TARG)


test: $(BIN)/$(TARG)
	./$(BIN)/$(TARG)

.PHONY: test
