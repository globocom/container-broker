$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
# require "container_broker/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "container_broker"
  spec.version     = "0.0.1"#ContainerBroker::VERSION
  spec.authors     = ["Douglas Lise", "Mateus Nava"]
  spec.email       = ["douglas.lise@corp.globo.com"]
  spec.homepage    = ""
  spec.summary     = "Summary of ContainerBroker."
  spec.description = "Description of ContainerBroker."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0.3", ">= 6.0.3.2"
end
#   gem "mongoid"
# gem "mongoid_enumerable"
# gem "mongoid_rails_migrations"
# gem "jbuilder", "~> 2.5"


# gem "e2mmap"
# gem "thwait"

# gem "puma", "~> 3.7"
# gem "rack-cors"

# # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# # Use Redis adapter to run Action Cable in production
# # gem 'redis', '~> 4.0'
# # Use ActiveModel has_secure_password
# # gem 'bcrypt', '~> 3.1.7'


# gem "bundler-audit"
# gem "byebug", platforms: %i[mri mingw x64_mingw]
# gem "fabrication"
# gem "rspec-rails", "~> 4.0.0"

# gem "database_cleaner"
# gem "mini_racer"
# gem "rspec-collection_matchers"
# gem "rspec-json_expectations"
# gem "rspec-nc"

# gem "listen", ">= 3.0.5", "< 3.2"
# gem "web-console", ">= 3.3.0"

# gem "spring"
# gem "spring-commands-rspec"
# gem "spring-watcher-listen", "~> 2.0.0"

# gem "active_model_serializers"
# gem "awesome_print"
# gem "backstage_api_client"
# gem "config"
# gem "guard-rspec"
# gem "idempotent-request"
# gem "kubeclient"
# gem "mongoid-uuid"
# gem "redis-namespace"
# gem "sentry-raven"
# gem "sidekiq"
# gem "sidekiq-failures"
# gem "sidekiq-pro"
# gem "sidekiq-scheduler"

# gem "measures", "~> 4.0"

# gem "rubocop", "~> 0.74.0"


# spec.add_development_dependency "sqlite3"
