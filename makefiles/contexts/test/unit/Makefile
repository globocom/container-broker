-include ../../prerequisites/tasks.mk

##>> run unit tests for all languages

.DEFAULT_GOAL := all
LANGUAGES := $(shell find . -type f -name "Makefile" | grep ".*/.*/Makefile" | cut -d/ -f2- | sed -E "s/\/Makefile//")

.PHONY: all $(LANGUAGES)

## all (default): run unit tests for all available languages
all: $(LANGUAGES)

## {language}: run all unit tests for {language}
$(LANGUAGES):
	@$(MAKE) -C $(@)/

## available: list available languages
available:
	@echo $(LANGUAGES)
