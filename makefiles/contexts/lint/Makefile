-include ../prerequisites/tasks.mk

##>> run lint for all languages

.DEFAULT_GOAL := all
LANGUAGES := $(shell find . -type f -name "Makefile" | grep ".*/.*/Makefile" | cut -d/ -f2- | sed -E "s/\/Makefile//")

.PHONY: all $(LANGUAGES)

## all (default): run lint for all available languages
all: $(LANGUAGES)

## {language}: run lint for {language}
$(LANGUAGES):
	@$(MAKE) -C $(@)/

## available: list available languages
available:
	@echo $(LANGUAGES)
