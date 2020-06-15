-include ../../prerequisites/tasks.mk
-include ../../prerequisites/ruby.mk

##>> run bundle audit

.DEFAULT_GOAL := all
.PHONY: all

## all (default): run bundle audit
all: bundle
	@cd $(base_path) && bundle exec bundle audit --update

ignore:
	@cd $(base_path) && bundle exec bundle audit --update --ignore $(advisories)
