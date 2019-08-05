.PHONY: generate_tasks
generate_tasks:
	bundle exec rails "task:random_generate[$(amount), $(max_sleep)]"
