# frozen_string_literal: true

source "https://rubygems.org/"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "mongoid"
gem "mongoid_enumerable"
gem "mongoid_rails_migrations"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.0"

gem "e2mmap"
gem "thwait"

# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
gem "puma", "~> 3.7"
gem "rack-cors"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.5"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem "docker-api"

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "fabrication"
  gem "rspec-rails", "~> 4.0.0"
end

group :test do
  gem "database_cleaner"
  gem "mini_racer"
  gem "rspec-collection_matchers"
  gem "rspec-json_expectations"
  gem "rspec-nc"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "web-console", ">= 3.3.0"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-commands-rspec"
  gem "spring-watcher-listen", "~> 2.0.0"
end

gem "active_model_serializers"
gem "awesome_print"
gem "backstage_api_client"
gem "config"
gem "guard-rspec"
gem "kubeclient"
gem "mongoid-uuid"
gem "redis-namespace"
gem "sentry-raven"
gem "sidekiq"
gem "sidekiq-failures"
gem "sidekiq-pro", ">= 4"
gem "sidekiq-scheduler"

gem "measures", "~> 4.0"

gem "rubocop", "~> 0.74.0"
