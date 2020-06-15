context_file ?= $(word 1,$(abspath $(MAKEFILE_LIST)))
context_name ?= $(shell echo $(dir $(context_file)) | sed -E "s/^.*\/contexts\/(.*)\/$$/\1/")

.PHONY: help description

help: description
	@sed -nE 's/^## (.*): (.*)$$/"\1" "\2"/p' $(context_file) | xargs printf "\033[34m  %-25s\033[0m%s\n"
	@echo

description:
	@sed -nE 's/^##>> (.*)$$/"\1"/p' $(context_file) | xargs printf "\033[37m%-25s\033[0m  \033[34m%-25s\033[0m%s\n" "[$(context_name)]"
