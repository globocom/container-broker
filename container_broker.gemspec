$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
# require "container_broker/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "container_broker"
  spec.version     = "0.0.1"#ContainerBroker::VERSION
  spec.authors     = ["Douglas Lise", "Mateus Nava", "João Vieira"]
  spec.email       = ["douglaslise@gmail.com", "nava.mateus@gmail.com", "joaocv3@gmail.com"]
  spec.homepage    = ""
  spec.summary     = "ContainerBroker"
  spec.description = "ContainerBroker"
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

  spec.add_dependency "mongoid"
  spec.add_dependency "mongoid_enumerable"

  # spec.add_dependency "mongoid_rails_migrations"
  # spec.add_dependency "jbuilder", "~> 2.5"
  # spec.add_dependency "e2mmap"
  # spec.add_dependency "thwait"

  spec.add_development_dependency "byebug"#, platforms: %i[mri mingw x64_mingw]
  spec.add_development_dependency "fabrication"
  spec.add_development_dependency "rspec-rails", "~> 4.0.0"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "rspec-collection_matchers"
  spec.add_development_dependency "rspec-json_expectations"
  spec.add_development_dependency "rspec-nc"

  spec.add_development_dependency "listen", ">= 3.0.5", "< 3.2"

  spec.add_development_dependency "spring"
  spec.add_development_dependency "spring-commands-rspec"
  spec.add_development_dependency "spring-watcher-listen", "~> 2.0.0"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "bundler-audit"

  spec.add_dependency "active_model_serializers"
  spec.add_dependency "config"
  spec.add_dependency "idempotent-request"
  spec.add_dependency "kubeclient"
  spec.add_dependency "mongoid-uuid"
  spec.add_dependency "redis-namespace"
  spec.add_dependency "sentry-raven"
  spec.add_dependency "sidekiq"
  spec.add_dependency "sidekiq-failures"
  spec.add_dependency "sidekiq-scheduler"
  spec.add_dependency "docker-api"
  spec.add_dependency "measures"
end
