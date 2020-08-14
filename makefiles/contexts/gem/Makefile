-include ../prerequisites/tasks.mk

##>> gem release cycle tasks

.PHONY: tag build publish
SHELL := /bin/bash

APP = $(shell grep "\.name" $(base_path)/*.gemspec | sed -E 's/.* = "(.*)"/\1/')
VERSION = $(shell grep VERSION $(base_path)/lib/$(APP)/version.rb | sed -E 's/.* = "(.*)"/\1/')
APP_VERSION = $(APP)-$(VERSION)
GEM_FILE = $(APP_VERSION).gem

## tag: create tag from version
tag:
ifeq ($(shell git tag -l $(VERSION)),)
	@if [ -d ../git ]; then \
		$(MAKE) -C ../git create_tag tag=$(VERSION);\
	else\
		git tag $(VERSION) -e --file=<(echo "$(VERSION) Release Notes");\
	fi;
endif

$(base_path)/$(GEM_FILE):
	@cd $(base_path) && gem build $(base_path)/$(APP).gemspec -o $(base_path)/$(GEM_FILE)

## build: build gem
build: $(base_path)/$(GEM_FILE)
	echo $(base_path)

## release: build, tag (from version) and release gem
release: build tag
	@echo "Publishing $(GEM_FILE)"
ifdef RUBYGEMS_HOST
	@gem push $(base_path)/$(GEM_FILE) --host $(RUBYGEMS_HOST)
else
	@gem push $(base_path)/$(GEM_FILE)
endif
