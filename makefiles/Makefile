.DEFAULT_GOAL := contexts_help

##>> Makefile

export setup_path = $(word 1,$(dir $(realpath $(MAKEFILE_LIST))))
export contexts_path = $(addsuffix contexts,$(setup_path))
main_makefile = $(word 1,$(abspath $(MAKEFILE_LIST)))
context_file = $(main_makefile)
context_name = main
setup_folder = $(lastword $(shell echo $(setup_path) | tr "/" " "))
contexts_folder = $(addsuffix /contexts,$(setup_folder))
export base_path = $(realpath $(contexts_path)/../../)

-include $(contexts_path)/prerequisites/tasks.mk

CONTEXTS = $(shell find $(setup_path) -type f -name "Makefile" | grep "contexts" | sed -E 's/^.*\/contexts\/(.*)\/Makefile$$/\1/')
CONTEXTS_TASKS = $(sort $(addsuffix /%,$(CONTEXTS)))
CONTEXTS_HELP = $(sort $(addsuffix /help,$(CONTEXTS)))
CONTEXTS_DESCRIPTION = $(sort $(addsuffix /description,$(CONTEXTS)))

.PHONY: $(CONTEXTS) $(CONTEXTS_HELP) $(CONTEXTS_DESCRIPTION) how_to setup_makefile update_makefile setup_context prerequisites contexts_help contexts

$(CONTEXTS_TASKS):
	@$(MAKE) $(@F) -C $(contexts_folder)/$(@D)/

$(CONTEXTS):
	@$(MAKE) -C $(contexts_folder)/$@

$(CONTEXTS_HELP) $(CONTEXTS_DESCRIPTION):
	@$(MAKE) $(@F) -C $(contexts_folder)/$(@D)/

contexts_help: $(CONTEXTS_HELP) how_to
contexts: $(CONTEXTS_DESCRIPTION) how_to

how_to:
	@echo
	@echo "How to run tasks:"
	@echo " - 'make {context}' (ex.:'make git')\t\t\t\t\truns default tasks in a context"
	@echo " - 'make {context}/{task}' (ex.: 'make todo/all')\t\t\truns a specific task inside a context"
	@echo " - 'make {context}/{subcontext}/{task}' (ex.: 'make test/unit/ruby')\truns a specific task inside a sub-context"
	@echo

## setup_makefile: symlink this Makefile into project home
setup_makefile: $(base_path)/Makefile prerequisites

$(base_path)/Makefile:
	@ln -sfv $(setup_folder)/Makefile $(base_path)/Makefile

prerequisites: $(contexts_path)/prerequisites/elixir.mk $(contexts_path)/prerequisites/javascript.mk $(contexts_path)/prerequisites/ruby.mk $(contexts_path)/prerequisites/tasks.mk

$(contexts_path)/prerequisites/%:
	@curl https://raw.githubusercontent.com/jvortmann/make-contexts/master/contexts/prerequisites/$(@F) -o $(contexts_path)/prerequisites/$(@F) -f --create-dirs 2>/dev/null

## update_makefile: download main Makefile latest version
update_makefile:
	@curl https://raw.githubusercontent.com/jvortmann/make-contexts/master/contexts/Makefile -o $(main_makefile) -f 2>/dev/null

context = $(shell echo $@ | sed -E "s/^setup_context\///")
## setup_context/{context}: setup specific context's Makefile locally
setup_context/%:
	@(curl https://raw.githubusercontent.com/jvortmann/make-contexts/master/contexts/$(context)/Makefile -o /tmp/contexts/$(context)/Makefile -f --create-dirs 2>/dev/null \
			&& mkdir -p $(contexts_path)/$(context)/ 2>&1 >/dev/null \
			&& mv /tmp/contexts/$(context)/Makefile $(contexts_path)/$(context)/Makefile 2>&1 >/dev/null \
			&& echo "Context downloaded to $(contexts_path)/$(context)/" \
			|| echo "Context not found") \
		&& rm -r /tmp/contexts/$(context) 2>&1 >/dev/null \
