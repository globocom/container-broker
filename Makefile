CONTEXTS = docs
CONTEXTS_TASKS = $(addsuffix /%,$(CONTEXTS))
CONTEXTS_HELP = $(addsuffix /help,$(CONTEXTS))

.PHONY: help $(CONTEXTS) $(CONTEXTS_HELP) generate_tasks

generate_tasks:
	bundle exec rails "task:random_generate[$(amount), $(max_sleep)]"


$(CONTEXTS_TASKS):
	@$(MAKE) $(@F) -C build/$(@D)/

$(CONTEXTS):
	@$(MAKE) -C build/$@

$(CONTEXTS_HELP):
	@$(MAKE) $(@F) -C build/$(@D)/

help: $(CONTEXTS_HELP)

.PHONY: lint_ruby lint_ruby_autocorrect
FILES := app config lib features spec Gemfile
RUBOCOP := bundle exec rubocop

lint_ruby:
		${RUBOCOP} ${FILES}

lint_ruby_autocorrect:
		${RUBOCOP} ${FILES} --auto-correct
