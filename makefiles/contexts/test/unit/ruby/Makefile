-include ../../../prerequisites/tasks.mk
-include ../../../prerequisites/ruby.mk

##>> run unit tests for ruby

.DEFAULT_GOAL := all
.PHONY: all parallel

export RAILS_ENV=test

## all (default): run ruby unit tests
all: bundle
	@cd $(base_path) && bundle exec rspec spec

## parallel: run ruby unit tests in parallel using 'knapsack'
parallel: bundle
	@cd $(base_path) && bundle exec rake parallel_tests:generate_rspec_knapsack_file knapsack:rspec
