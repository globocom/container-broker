-include ../prerequisites/tasks.mk

##>> run tests

.DEFAULT_GOAL := all
TYPES := $(shell find . -type f -name "Makefile" | grep "\./\(\w\+/\)\{1\}Makefile" | cut -d/ -f2- | sed -E "s/\/Makefile//")
.PHONY: all $(TYPES)

## all (default): run all available test types
all: $(TYPES)

## {type}: run all {type} tests
$(TYPES):
	@$(MAKE) -C $(@)/

## available: list available languages
available:
	@echo $(TYPES)
