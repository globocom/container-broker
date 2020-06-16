-include ../../prerequisites/tasks.mk
-include ../../prerequisites/ruby.mk

##>> run lint for ruby

.DEFAULT_GOAL := all
.PHONY: all

export RAILS_ENV=test

RUBY_FILES = $(abspath $(addprefix $(base_path)/,app config lib features spec Gemfile))
RUBOCOP = bundle exec rubocop

## all (default): run lint for ruby files
all: bundle
	@cd $(base_path) && $(RUBOCOP) $(RUBY_FILES)

## autocorrect: run lint for ruby files and autocorrect errors
autocorrect: bundle
	@cd $(base_path) && $(RUBOCOP) $(RUBY_FILES) --auto-correct
